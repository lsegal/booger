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
        node[0].type = :result if node == s(:var_ref, s(:gvar, "$result"))
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
end

class YARD::Tags::Library
  define_tag 'Precondition', :requires, Booger::ExpressionTag
  define_tag 'Postcondition', :ensures, Booger::ExpressionTag
  define_tag 'Modifies Clause', :modifies, Booger::ExpressionTag
  define_tag 'AST', :ast, Booger::ExpressionTag
end
