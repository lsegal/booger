require_relative 'node'

module Booger
  module Boogie
    module AST
      class Expression < Node; end

      class Parameter < Expression
        attr_accessor :name
        attr_accessor :type
        def to_s; "#{name}: VALUE" end
      end
    
      class BinaryExpression < Expression
        attr_accessor :lhs, :op, :rhs
        def to_s; "#{lhs} #{op} #{rhs}" end
      end
      
      class TokenExpression < Expression
        attr_accessor :token
        alias to_s token
      end
      
      class FieldReference < Expression
        attr_accessor :field
        def to_s; "#{field.name}[self]" end
      end
    end
  end
end