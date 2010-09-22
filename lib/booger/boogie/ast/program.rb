require 'booger/boogie/ast/node'

module Booger
  module Boogie
    module AST
      class Program < Node
        default :procedures, []
      
        def to_buf(buf)
          procedures.each {|p| p.to_buf(buf); buf.append_line("") }
        end
      end
    end
  end
end
