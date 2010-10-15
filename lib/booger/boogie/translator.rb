require_relative 'ast/procedure'
require_relative 'ast/program'
require_relative 'ast/statement'
require_relative 'ast/expression'

module Booger
  module Boogie
    class Translator
      include AST
    
      attr_accessor :program, :procedure, :varmap
    
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
        self.varmap = {}
        self.procedure = Procedure.new(loc: meth)
        return_type = program.type(meth.tag(:return))
        procedure.returns = Parameter.new(name: "$result", type: program.type(meth.tag(:return)))
        procedure.name = meth.path
        procedure.params = meth.parameters.map {|k,v| Parameter.new(name: k, type: program.type(meth.tags(:param).find {|x| x.name == k })) }
        procedure.statements = visit(ast)
        unless procedure.statements.last.is_a?(ReturnStatement)
          procedure.statements << ReturnStatement.new(loc: ast.last, procedure: procedure)
        end
        %w(requires ensures modifies).each do |tname|
          meth.tags(tname).each do |tag|
            procedure.contracts << ContractStatement.new(name: tname, expression: visit(tag.expression), loc: tag, procedure: procedure)
          end
        end
        procedure
      end
    
      def translate_binary(bin)
        BinaryExpression.new(lhs: visit(bin[0]), op: bin[1], rhs: visit(bin[2]), loc: bin)
      end
    
      def translate_return(ret)
        ReturnStatement.new(expression: visit(ret.first.first), loc: ret.first.first)
      end
    
      def translate_var_ref(ref) TokenExpression.new(token: varmap[ref.source] || ref.source) end
      def translate_int(int) TokenExpression.new(token: int.source) end
        
      def translate_if(stmt)
        node = IfStatement.new(condition: visit(stmt.condition), then: visit(stmt.then_block), else: visit(stmt.else_block), procedure: procedure, loc: stmt.condition)
      end
      
      def translate_assign(assign)
        case assign[0].type
        when :var_field
          name = assign.first.source
          if procedure.params.find {|p| p.name == name } # it's a parameter
            # we need to rewrite this variable name, since you can't assign to parameters in Boogie
            varmap[name] = (name += "0")
          end
          declare_local(name)
          AssignmentStatement.new(lhs: TokenExpression.new(token: name), rhs: visit(assign[1]), procedure: procedure, loc: assign)
        end
      end
      
      def translate_result(res)
        "$result"
      end
    
      def translate_old(old)
        "old(#{visit(old[0])})"
      end
    
      private
      
      def declare_local(name, type)
        procedure.locals[name] = LocalDeclarationStatement.new(name: name, type: type, procedure: procedure)
      end
    
      def visit(node)
        return node.map {|n| visit(n) } if node.type == :list
        m = "translate_#{node.type}"
        send(m, node) if respond_to?(m)
      end
    end
  end
end