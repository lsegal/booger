require_relative 'node'

module Booger
  module Boogie
    module AST
      class Constant < Node
        default :type, 'VALUE'
        attr_accessor :name
        
        def to_buf(buf)
          buf.append_line("const #{name}: #{type};")
        end
      end
    end
  end
end