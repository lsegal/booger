require 'booger/boogie/ast/node'

module Booger
  module Boogie
    module AST
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
      
      class TokenExpression < Expression
        attr_accessor :token
        alias to_s token
      end
    end
  end
end