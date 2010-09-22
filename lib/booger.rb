require 'benchmark'
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
      bpl = nil
      time = Benchmark.measure do 
        program = parse(source) 
        bpl = Boogie::Output.new
        program.to_buf(bpl)
      end
      puts "====== Boogie Output (#{base}) (#{'%.2f' % time.total}s) ======\n\n#{bpl}" if debug
      file.puts(bpl)
      file.flush
      unless ENV['DRYRUN']
        cmd = "boogie /nologo #{base}"
        puts ">> Running: `#{cmd}'...\n\n" if debug
        results = nil
        time = Benchmark.measure { results = `#{cmd}` }
        puts "====== Boogie Results (#{'%.2f' % time.total}s) ======\n\n#{results}\n" if debug
        puts "====== Results ======\n\n" if debug
        puts Boogie::Results.new(results, bpl.nodemap).to_s
      end
    end
  end
  
  class CLI
    def initialize(*args)
      Booger.run(args.size > 0 ? File.read(args.first) : STDIN.read)
    end
  end
end
