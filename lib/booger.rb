require 'booger/yard_ext'
require 'booger/boogie/ast/program'
require 'booger/boogie/output'
require 'booger/boogie/results'
require 'booger/boogie/translator'

module Booger
  def self.parse(str)
    YARD::Registry.clear
    YARD.parse_string(str)
    program = Boogie::AST::Program.new
    translator = Boogie::Translator.new(program)
    translator.translate_methods
    program
  end
  
  def self.run(source, debug = ENV['RESULTS'])
    require 'tempfile'
    Tempfile.open(%w(boogie .bpl), Dir.pwd) do |file|
      base = File.basename(file.path)
      program = parse(source)
      bpl = Boogie::Output.new
      program.to_buf(bpl)
      puts "====== Boogie contents ======\n\n#{bpl}\n\n" if debug
      file.puts(bpl)
      file.flush
      puts "Running: boogie #{base}" if debug
      results = `boogie #{base}`
      puts "====== Boogie Results ======\n\n#{results}\n\n" if debug
      puts Boogie::Results.new(results, bpl.nodemap).to_s
    end
  end
  
  class CLI
    def initialize(*args)
      Booger.run(args.size > 0 ? File.read(args.first) : STDIN.read)
    end
  end
end
