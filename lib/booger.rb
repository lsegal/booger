require 'yard'

module Booger
  class ExpressionTag < YARD::Tags::Tag
    include YARD::Parser::Ruby
    
    attr_accessor :expression
    def initialize(tag, expr)
      super(tag, nil)
      self.expression = parse_expr(expr)
    end
    
    private
    
    def parse_expr(expr)
      return expr if expr.is_a?(AstNode)
      expr = RubyParser.new(expr, '<stdin>').parse.enumerator[0]
      expr.traverse do |node|
        node[0].type = :result if node == s(:var_ref, s(:ident, '__result__'))
        if node.type == :fcall && node[0] == s(:ident, "old")
          node.type = :old 
          node.replace(node.parameters[0])
        end
      end
      expr
    end
  end
  
  class MethodHandler < YARD::Handlers::Ruby::MethodHandler
    handles :def
    
    def register(obj) super; @obj = obj end
    
    def process
      super
      @obj.docstring.add_tag(ExpressionTag.new(:ast, statement.last))
    end
  end
  
  def self.parse(str)
    YARD::Registry.clear
    YARD.parse_string(str)
    program = Boogie::AST::Program.new
    translator = Boogie::Translator.new(program)
    translator.translate_methods
    program
  end
  
  def self.run(source, debug = ENV['RESULTS'])
    require 'tempfile'
    Tempfile.open(%w(boogie .bpl), Dir.pwd) do |file|
      base = File.basename(file.path)
      program = parse(source)
      bpl = Boogie::Output.new
      program.to_buf(bpl)
      puts "====== Boogie contents ======\n\n#{bpl}\n\n" if debug
      file.puts(bpl)
      file.flush
      puts "Running: boogie #{base}" if debug
      results = `boogie #{base}`
      puts "====== Boogie Results ======\n\n#{results}\n\n" if debug
      puts Results.new(results, bpl.nodemap).to_s
    end
  end
  
  class Results
    attr_accessor :errors, :nodemap
    
    def initialize(output, nodemap)
      self.errors = {}
      self.nodemap = nodemap
      parse_results(output)
    end
    
    def valid?; errors.size == 0 end
    
    def to_s
      return "Success." if valid?
      out = "Verification Errors (#{errors.size}):\n\n"
      errors.each do |point, error|
        out << "- " + error + ":"
        case pt = nodemap[point]
        when ExpressionTag
          out << "\n      @#{pt.tag_name} #{pt.expression.source}"
        when YARD::Tags::Tag
          out << "\n      @#{pt.tag_name} #{pt.text}"
        when YARD::Parser::Ruby::AstNode
          out << pt.line.to_s + ":\n      " + pt.source
        end
        out << "\n\n"
      end
      out
    end
    
    private
    
    def parse_results(output)
      output.split(/\r?\n/).each do |line|
        if line =~ /\((\d+),(\d+)\):[^:]+: (.+might not hold.*?)\.?$/
          errors[[$1.to_i, $2.to_i]] = $3
        end 
      end
    end
  end
  
  module Boogie
    class Output < String
      attr_accessor :indent
      attr_accessor :nodemap
      
      def initialize
        @newline = false
        @source_point = [1,1]
        self.nodemap = {}
        self.indent = 0
        class << @source_point
          def col; self[1] end
          def row; self[0] end
          def col=(val); self[1] = val end
          def row=(val); self[0] = val end
        end
      end
      
      def append(str, node = nil)
        if @newline && indent > 0
          extra_indent = "  " * indent 
          self << extra_indent
          @source_point.col += extra_indent.size
        end
        nodemap[@source_point.dup] = node if node
        self << str.to_s
        @newline = false
        @source_point.col += str.to_s.size
      end
      
      def append_line(str, node = nil)
        append(str, node)
        self << "\n"
        @newline = true
        @source_point.row += 1
        @source_point.col = 1
      end
      
      def indent(&block)
        return @indent unless block_given?
        @indent += 1
        yield
        @indent -= 1
        @indent
      end
    end
    
    module AST
      class Node
        attr_accessor :loc
        
        def self.default(attr, default = nil)
          attr_accessor attr
          defaults[attr] = default
        end
        def self.defaults; @defaults ||= {} end
        
        def initialize(opts = {})
          apply_defaults
          opts.each do |k,v|
            send("#{k}=", v) if respond_to?("#{k}=")
          end
        end
        
        def to_s; to_buf(o = Output.new); o end
        def to_buf(o) o.append(to_s, loc) end
        
        private
        
        def apply_defaults
          self.class.defaults.each do |k,v|
            send("#{k}=", v.clone)
          end
        end
      end
      
      class Procedure < Node
        attr_accessor :name, :returns
        default :params, []
        default :statements, []
        default :contracts, []
        
        def to_buf(buf)
          buf.append("procedure #{name}(#{params.join(", ")})#{to_buf_returns}", loc)
          contracts.each {|c| buf.append(" "); c.to_buf(buf) }
          buf.append_line(" {")
          buf.indent { statements.each {|s| s.to_buf(buf) } }
          buf.append_line("}")
        end
        
        private
        
        def to_buf_returns
          returns ? " returns (__result__ : int)" : ""
        end
        
        def to_s_contracts
          contracts.empty? ? "" : contracts.join(" ") + " "
        end
      end
      
      class Program < Node
        default :procedures, []
        
        def to_buf(buf)
          procedures.each {|p| p.to_buf(buf); buf.append_line("") }
        end
      end
      
      class Statement < Node
        def to_buf(o) o.append_line(to_s, loc) end
      end
      
      class ContractStatement < Statement
        attr_accessor :name, :expression
        def to_s; "#{name} #{expression};" end
        def to_buf(o) o.append(to_s, loc) end
      end
      
      class AssignmentStatement < Statement
        attr_accessor :lhs, :rhs
        def to_s; "#{lhs} := #{rhs};" end
      end
      
      class AssertStatement < Statement
        attr_accessor :expression
        def to_s; "assert #{expression};" end
      end
      
      class AssumeStatement < Statement
        attr_accessor :expression
        def to_s; "assume #{expression};" end
      end
      
      class ReturnStatement < Statement
        attr_accessor :expression
        def to_buf(o)
          o.append_line("__result__ := #{expression};") if expression
          o.append_line("return;", loc)
        end
      end
      
      class Expression < Node; end

      class Parameter < Expression
        attr_accessor :name
        default :type, 'int'
        def to_s; "#{name}: #{type}" end
      end
      
      class BinaryExpression < Expression
        attr_accessor :lhs, :op, :rhs
        def to_s; "#{lhs} #{op} #{rhs}" end
      end
    end

    class Translator
      include AST
      
      attr_accessor :program
      
      def initialize(program = nil)
        self.program = program || Program.new
      end
      
      def translate_methods
        YARD::Registry.all(:method).each do |meth|
          program.procedures << translate_method(meth)
        end
      end
      
      def translate_method(meth)
        ast = meth.tag(:ast).expression
        proc = Procedure.new(returns: Parameter.new(name: "__return__", type: "int"), loc: meth)
        proc.name = meth.path
        proc.params = meth.parameters.map {|k,v| Parameter.new(name: k) }
        ast.each do |statement|
          m = "translate_#{statement.type}"
          proc.statements << visit(statement)
        end
        unless proc.statements.last.is_a?(ReturnStatement)
          proc.statements << ReturnStatement.new(loc: ast.last)
        end
        meth.tags(:require).each do |req|
          proc.contracts << ContractStatement.new(name: 'requires', expression: visit(req.expression), loc: req)
        end
        meth.tags(:ensure).each do |req|
          proc.contracts << ContractStatement.new(name: 'ensures', expression: visit(req.expression), loc: req)
        end
        proc
      end
      
      def translate_binary(bin)
        BinaryExpression.new(lhs: visit(bin[0]), op: bin[1], rhs: visit(bin[2]), loc: bin)
      end
      
      def translate_return(ret)
        ReturnStatement.new(expression: visit(ret.first.first), loc: ret.first.first)
      end
      
      def translate_var_ref(ref) ref.source end
      def translate_int(int) int.source end
        
      def translate_result(res)
        "__result__"
      end
      
      def translate_old(old)
        "old(#{visit(old[0])})"
      end
      
      private
      
      def visit(node)
        return node.map {|n| visit(n) } if node.type == :list
        m = "translate_#{node.type}"
        send(m, node) if respond_to?(m)
      end
    end
  end
  
  class CLI
    def initialize(*args)
      Booger.run(args.size > 0 ? File.read(args.first) : STDIN.read)
    end
  end
end

class YARD::Tags::Library
  define_tag 'Precondition', :require, Booger::ExpressionTag
  define_tag 'Postcondition', :ensure, Booger::ExpressionTag
  define_tag 'AST', :ast, Booger::ExpressionTag
end

