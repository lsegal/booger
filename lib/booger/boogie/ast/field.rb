require_relative 'node'

module Booger
  module Boogie
    module AST
      class Field < Node
        attr_accessor :name
        default :type, 'Object'
        
        def to_buf(buf)
          buf.append_line("var #{name}: [VALUE]VALUE;")
        end
      end
    end
  end
end