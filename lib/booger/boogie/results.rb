module Booger
  module Boogie
    class Results
      attr_accessor :errors, :nodemap

      def initialize(output, nodemap)
        self.errors = {}
        self.nodemap = nodemap
        parse_results(output)
      end

      def valid?; errors.size == 0 end

      def to_s
        return "Success." if valid?
        out = "Verification Errors (#{errors.size}):\n\n"
        errors.each do |point, error|
          out << "- " + error + ":"
          case pt = nodemap[point]
          when ExpressionTag
            out << "\n      @#{pt.tag_name} #{pt.expression.source}"
          when YARD::Tags::Tag
            out << "\n      @#{pt.tag_name} #{pt.text}"
          when YARD::Parser::Ruby::AstNode
            out << pt.line.to_s + ":\n      " + pt.source
          end
          out << "\n\n"
        end
        out
      end

      private

      def parse_results(output)
        output.split(/\r?\n/).each do |line|
          if line =~ /\((\d+),(\d+)\):[^:]+: (.+might not hold.*?)\.?$/
            errors[[$1.to_i, $2.to_i]] = $3
          end 
        end
      end
    end
  end
end