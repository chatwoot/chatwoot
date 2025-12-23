# frozen_string_literal: true
require_relative '../tilt'
require 'optparse'

module Tilt::CLI
  USAGE = (<<USAGE).freeze
Usage: tilt <options> <file>
Process template <file> and write output to stdout. With no <file> or
when <file> is '-', read template from stdin and use the --type option
to determine the template's type.

Options
  -l, --list                List template engines + file patterns and exit
  -t, --type=<pattern>      Use this template engine; required if no <file>
  -y, --layout=<file>       Use <file> as a layout template

  -D<name>=<value>          Define variable <name> as <value>
  -d, --define-file=<file>  Load YAML from <file> and use for variables
  --vars=<ruby>             Evaluate <ruby> to Hash and use for variables

  -h, --help                Show this help message

Convert markdown to HTML:
  $ tilt foo.markdown > foo.html

Process ERB template:
  $ echo "Answer: <%= 2 + 2 %>" | tilt -t erb
  Answer: 4

Define variables:
  $ echo "Answer: <%= 2 + n %>" | tilt -t erb --vars="{:n=>40}"
  Answer: 42
  $ echo "Answer: <%= 2 + n.to_i %>" | tilt -t erb -Dn=40
  Answer: 42
USAGE
  private_constant :USAGE

  # Backbone of the tilt command line utility. Allows mocking input/output
  # for simple testing. Returns program exit code.
  def self.run(argv: ARGV, stdout: $stdout, stdin: $stdin, stderr: $stderr, script_name: File.basename($0))
    pattern = nil
    layout = nil
    locals = {}
    abort = proc do |msg|
      stderr.puts msg
      return 1
    end

    OptionParser.new do |o|
      o.program_name = script_name

      # list all available template engines
      o.on("-l", "--list") do
        groups = {}
        Tilt.lazy_map.each do |pattern,engines|
          engines.each do |engine,|
            engine = engine.split('::').last.sub(/Template\z/, '')
            (groups[engine] ||= []) << pattern
          end
        end
        groups.sort { |(k1,v1),(k2,v2)| k1 <=> k2 }.each do |engine,files|
          stdout.printf "%-20s %s\n", engine, files.sort.join(', ')
        end
        return 0
      end

      # the template type / pattern
      o.on("-t", "--type=PATTERN", String) do |val|
        abort.("unknown template type: #{val}") unless Tilt[val]
        pattern = val
      end

      # pass template output into the specified layout template
      o.on("-y", "--layout=FILE", String)  do |file|
        paths = [file, "~/.tilt/#{file}", "/etc/tilt/#{file}"]
        layout = paths.
          map  { |p| File.expand_path(p) }.
          find { |p| File.exist?(p) }
        abort.("no such layout: #{file}") if layout.nil?
      end

      # define a local variable
      o.on("-D", "--define=PAIR", String) do |pair|
        key, value = pair.split(/[=:]/, 2)
        locals[key.to_sym] = value
      end

      # define local variables from YAML or JSON
      o.on("-d", "--define-file=FILE", String) do |file|
        require 'yaml'
        abort.("no such define file: #{file}") unless File.exist? file
        hash = File.open(file, 'r:bom|utf-8') { |f| YAML.load(f.read) }
        abort.("vars must be a Hash, not instance of #{hash.class}") unless hash.is_a?(Hash)
        hash.each { |key, value| locals[key.to_sym] = value }
      end

      # define local variables using a Ruby hash
      o.on("--vars=RUBY") do |ruby|
        hash = eval(ruby)
        abort.("vars must be a Hash, not instance of #{hash.class}") unless hash.is_a?(Hash)
        hash.each { |key, value| locals[key.to_sym] = value }
      end

      o.on_tail("-h", "--help") do
        stdout.puts USAGE
        return 0
      end
    end.parse!(argv)

    file = argv.first || '-'
    pattern = file if pattern.nil?
    abort.("template type not given. see: #{script_name} --help") if ['-', ''].include?(pattern)

    engine = Tilt[pattern]
    abort.("template engine not found for: #{pattern}") unless engine

    template =
      engine.new(file) {
        if file == '-'
          stdin.read
        else
          File.read(file)
        end
      }
    output = template.render(self, locals)

    # process layout
    output = Tilt.new(layout).render(self, locals) { output } if layout

    stdout.write(output)

    0
  end
end
