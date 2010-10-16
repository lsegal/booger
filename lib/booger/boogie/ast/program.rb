require_relative 'node'
require_relative 'constant'

module Booger
  module Boogie
    module AST
      class Program < Node
        default :procedures, []
        default :globals, ["type VALUE = int;"]
        default :types, {"Object" => "BasicObject"}
        default :constants, {
          "BasicObject" => Constant.new(name: "BasicObject"),
          "Object" => Constant.new(name: "Object")
        }
        default :fields, {}

        def to_buf(buf)
          globals.each {|h| buf.append_line(h) }
          constants.values.each {|c| c.to_buf(buf) }
          types.each {|k,v| buf.append_line("axiom #{k} <: #{v};")}
          fields.values.each {|f| f.to_buf(buf) }
          buf.append_line("")
          procedures.each {|p| p.to_buf(buf); buf.append_line("") }
        end
        
        def type(name, superklass = "Object")
          unless name
            name = "Object"
            superklass = "BasicObject"
          end
          superklass = "BasicObject" if name == "Object" && superklass == "Object"
          const = case name
          when Fixnum; FixnumConstant.new(name: name)
          when String; Constant.new(name: name)
          when YARD::Tags::Tag; Constant.new(name: name.types.first || "Object")
          end
          constants[const.name] = const
          types[const.name] = superklass
          const.name
        end
      end
    end
  end
end
