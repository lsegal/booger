require 'booger/boogie/ast/node'
require 'booger/boogie/ast/procedure'

module Booger
  module Boogie
    module AST
      class Statement < Node
        attr_accessor :procedure
        def to_buf(o) o.append_line(to_s, loc) end
      end
    
      class ContractStatement < Statement
        attr_accessor :name, :expression
        def to_s; "#{name} #{expression};" end
        def to_buf(o) o.append(to_s, loc) end
      end
    
      class AssignmentStatement < Statement
        attr_accessor :lhs, :rhs
        def to_s; "#{lhs} := #{rhs};" end
      end
    
      class AssertStatement < Statement
        attr_accessor :expression
        def to_s; "assert #{expression};" end
      end
    
      class AssumeStatement < Statement
        attr_accessor :expression
        def to_s; "assume #{expression};" end
      end
    
      class ReturnStatement < Statement
        attr_accessor :expression
        def to_buf(o)
          o.append_line("__result__ := #{expression};") if expression
          o.append_line("return;", loc)
        end
      end
      
      class IfStatement < Statement
        attr_accessor :condition, :then, :else
        default :elsifs, []
        
        def to_buf(o)
          
        end
      end
      
      class LabelStatement < Statement
      end
    end
  end
end