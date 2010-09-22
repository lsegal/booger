require 'booger/boogie/ast/node'

module Booger
  module Boogie
    module AST
      class Procedure < Node
        attr_accessor :name, :returns
        default :params, []
        default :statements, []
        default :contracts, []
        default :labels, []
      
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
    end
  end
end