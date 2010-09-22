require 'booger/boogie/ast/procedure'
require 'booger/boogie/ast/program'
require 'booger/boogie/ast/statement'
require 'booger/boogie/ast/expression'

module Booger
  module Boogie
    class Translator
      include AST
    
      attr_accessor :program, :procedure
    
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
        self.procedure = Procedure.new(loc: meth)
        procedure.returns = Parameter.new(name: "__return__", type: "int")
        procedure.name = meth.path
        procedure.params = meth.parameters.map {|k,v| Parameter.new(name: k) }
        ast.each do |statement|
          m = "translate_#{statement.type}"
          procedure.statements << visit(statement)
        end
        unless procedure.statements.last.is_a?(ReturnStatement)
          procedure.statements << ReturnStatement.new(loc: ast.last, procedure: procedure)
        end
        meth.tags(:require).each do |req|
          procedure.contracts << ContractStatement.new(name: 'requires', expression: visit(req.expression), loc: req, procedure: procedure)
        end
        meth.tags(:ensure).each do |req|
          procedure.contracts << ContractStatement.new(name: 'ensures', expression: visit(req.expression), loc: req, procedure: procedure)
        end
        procedure
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
end