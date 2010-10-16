require_relative 'node'
require_relative 'statement'

module Booger
  module Boogie
    module AST
      class Procedure < Node
        attr_accessor :name, :returns
        default :params, []
        default :statements, []
        default :contracts, []
        default :labels, []
        default :locals, {}
      
        def to_buf(buf)
          _params = [Parameter.new(name: 'self')] + params
          buf.append("procedure #{name}(#{_params.join(", ")})#{to_buf_returns}", loc)
          contracts.each {|c| buf.append(" "); c.to_buf(buf) }
          buf.append_line(" {")
          buf.indent do 
            locals.values.each {|l| l.to_buf(buf) }
            statements.each {|s| next unless s; s.to_buf(buf) }
          end
          buf.append_line("}")
        end
      
        private
      
        def to_buf_returns
          returns ? " returns (#{returns.name}: VALUE)" : ""
        end
      
        def to_s_contracts
          contracts.empty? ? "" : contracts.join(" ") + " "
        end
      end
    end
  end
end