require_relative 'ast/procedure'
require_relative 'ast/program'
require_relative 'ast/statement'
require_relative 'ast/expression'
require_relative 'ast/field'

module Booger
  module Boogie
    class Translator
      include AST
    
      attr_accessor :program, :procedure, :varmap, :meth, :in_modifies
    
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
        self.meth = meth
        return_type = program.type(meth.tag(:return))
        procedure.returns = Parameter.new(name: "$result", type: program.type(meth.tag(:return)))
        procedure.name = meth.path
        procedure.params = meth.parameters.map {|k,v| Parameter.new(name: k, type: program.type(meth.tags(:param).find {|x| x.name == k })) }
        procedure.statements = visit(ast).flatten
        unless procedure.statements.last.is_a?(ReturnStatement)
          procedure.statements << ReturnStatement.new(loc: ast.last, procedure: procedure)
        end
        %w(requires ensures modifies).each do |tname|
          meth.tags(tname).each do |tag|
            self.in_modifies = true if tname == "modifies"
            procedure.contracts << ContractStatement.new(name: tname, expression: visit(tag.expression), loc: tag, procedure: procedure)
            self.in_modifies = false
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
    
      def translate_var_ref(ref) visit(ref[0]) end
      def translate_int(int) TokenExpression.new(token: int.source) end
        
      def translate_if(stmt)
        node = IfStatement.new(condition: visit(stmt.condition), then: visit(stmt.then_block), else: visit(stmt.else_block), procedure: procedure, loc: stmt.condition)
      end
      
      def translate_assign(assign)
        return translate_call_assign(assign) if assign.last.type == :call
        case assign[0].type
        when :var_field
          name = assign.first.source
          if procedure.params.find {|p| p.name == name } # it's a parameter
            # we need to rewrite this variable name, since you can't assign to parameters in Boogie
            varmap[name] = (name += "0")
          end
          AssignmentStatement.new(lhs: visit(assign[0][0]), rhs: visit(assign[1]), procedure: procedure, loc: assign)
        end
      end
      
      def translate_call_assign(assign)
        stmt = nil
        call = assign[1]
        if call[0][0].type == :const && call.last.source == "new"
          declare_local(assign[0].source, program.type(call[0][0].source))
          if init = YARD::Registry.at(call[0].source + "#initialize")
            declare_local("unused")
            stmt = CallAssignmentStatement.new(procedure: procedure, loc: assign)
            stmt.rhs = CallStatement.new(procedure: procedure, loc: assign, name: init.path, parameters: [visit(assign[0][0])])
            stmt.lhs = TokenExpression.new(token: "unused")
          end
        else
          declare_local(assign[0].source)
        end
        if stmt.nil?
          stmt = CallAssignmentStatement.new(lhs: visit(assign[0][0]), rhs: visit(assign[1]), procedure: procedure, loc: assign)
        end
        stmt
      end
      
      def translate_ivar(ivar)
        name = meth.namespace.path + "$" + ivar[0][1..-1]
        program.fields[name] ||= Field.new(name: name)
        if in_modifies
          TokenExpression.new(token: name)
        else
          FieldReference.new(field: program.fields[name])
        end
      end
      
      def translate_string_literal(str)
        if in_modifies
          TokenExpression.new(token: str.jump(:tstring_content)[0].gsub('@', '$'))
        else
          nil
        end
      end
      
      def translate_ident(ident)
        name = ident.source
        declare_local(name) unless name[0] == "$"
        TokenExpression.new(token: name)
      end
      
      def translate_array(array)
        @@arrays ||= 0
        name = "ARRAY$#{@@arrays += 1}"
        declare_local(name, program.type('Array'))
        TokenExpression.new(token: name)
      end
      
      def translate_result(res)
        "$result"
      end
    
      def translate_old(old)
        "old(#{visit(old[0])})"
      end
      
      def translate_call(call)
        if call[0][0].type == :const && call.last.source == "new"
          nil
        else
          obj = visit(call[0])
          typeklass = nil
          case obj
          when FieldReference
            typeklass = obj.field.type
          when TokenExpression
            if local = procedure.locals[obj.token]
              typeklass = local.type
            end
          end
          if typeklass && m = YARD::Registry.at(typeklass + '#' + call.last.source)
            CallStatement.new(name: m.path, parameters: [obj], procedure: procedure, loc: call)
          end
        end
      end
    
      private
      
      def declare_local(name, type = program.type('Object'))
        return if procedure.params.any? {|x| x.name == name }
        procedure.locals[name] ||= LocalDeclarationStatement.new(name: name, type: type, procedure: procedure)
      end
    
      def visit(node)
        return node.map {|n| visit(n) } if node.type == :list
        m = "translate_#{node.type}"
        send(m, node) if respond_to?(m)
      end
    end
  end
end