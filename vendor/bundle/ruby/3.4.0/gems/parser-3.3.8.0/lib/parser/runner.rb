# frozen_string_literal: true

require 'find'
require 'optparse'

require_relative '../parser'

module Parser

  class Runner
    def self.go(options)
      new.execute(options)
    end

    def initialize
      @option_parser = OptionParser.new { |opts| setup_option_parsing(opts) }
      @legacy = {}
      @parser_class  = nil
      @parser        = nil
      @files         = []
      @fragments     = []
      @warnings      = false
      @benchmark     = false

      @source_count = 0
      @source_size  = 0
    end

    def execute(options)
      parse_options(options)
      setup_builder_default
      prepare_parser

      process_all_input
    end

    private

    LEGACY_MODES = %i[lambda procarg0 encoding index arg_inside_procarg0 forward_arg kwargs match_pattern].freeze

    def runner_name
      raise NotImplementedError, "implement #{self.class}##{__callee__}"
    end

    def setup_option_parsing(opts)
      opts.banner = "Usage: #{runner_name} [options] FILE|DIRECTORY..."

      opts.on_tail '-h', '--help', 'Display this help message and exit' do
        puts opts.help
        puts <<-HELP

  If you specify a DIRECTORY, then all *.rb files are fetched
  from it recursively and appended to the file list.

  The default parsing mode is for current Ruby (#{RUBY_VERSION}).
        HELP
        exit
      end

      opts.on_tail '-V', '--version', 'Output version information and exit' do
        puts "#{runner_name} based on parser version #{Parser::VERSION}"
        exit
      end

      opts.on '--18', 'Parse as Ruby 1.8.7 would' do
        require_relative 'ruby18'
        @parser_class = Parser::Ruby18
      end

      opts.on '--19', 'Parse as Ruby 1.9.3 would' do
        require_relative 'ruby19'
        @parser_class = Parser::Ruby19
      end

      opts.on '--20', 'Parse as Ruby 2.0 would' do
        require_relative 'ruby20'
        @parser_class = Parser::Ruby20
      end

      opts.on '--21', 'Parse as Ruby 2.1 would' do
        require_relative 'ruby21'
        @parser_class = Parser::Ruby21
      end

      opts.on '--22', 'Parse as Ruby 2.2 would' do
        require_relative 'ruby22'
        @parser_class = Parser::Ruby22
      end

      opts.on '--23', 'Parse as Ruby 2.3 would' do
        require_relative 'ruby23'
        @parser_class = Parser::Ruby23
      end

      opts.on '--24', 'Parse as Ruby 2.4 would' do
        require_relative 'ruby24'
        @parser_class = Parser::Ruby24
      end

      opts.on '--25', 'Parse as Ruby 2.5 would' do
        require_relative 'ruby25'
        @parser_class = Parser::Ruby25
      end

      opts.on '--26', 'Parse as Ruby 2.6 would' do
        require_relative 'ruby26'
        @parser_class = Parser::Ruby26
      end

      opts.on '--27', 'Parse as Ruby 2.7 would' do
        require_relative 'ruby27'
        @parser_class = Parser::Ruby27
      end

      opts.on '--30', 'Parse as Ruby 3.0 would' do
        require_relative 'ruby30'
        @parser_class = Parser::Ruby30
      end

      opts.on '--31', 'Parse as Ruby 3.1 would' do
        require_relative 'ruby31'
        @parser_class = Parser::Ruby31
      end

      opts.on '--32', 'Parse as Ruby 3.2 would' do
        require_relative 'ruby32'
        @parser_class = Parser::Ruby32
      end

      opts.on '--33', 'Parse as Ruby 3.3 would' do
        require_relative 'ruby33'
        @parser_class = Parser::Ruby33
      end

      opts.on '--34', 'Parse as Ruby 3.4 would' do
        require_relative 'ruby34'
        @parser_class = Parser::Ruby34
      end

      opts.on '--mac', 'Parse as MacRuby 0.12 would' do
        require_relative 'macruby'
        @parser_class = Parser::MacRuby
      end

      opts.on '--ios', 'Parse as mid-2015 RubyMotion would' do
        require_relative 'rubymotion'
        @parser_class = Parser::RubyMotion
      end

      opts.on '--legacy', "Parse with all legacy modes" do
        @legacy = Hash.new(true)
      end

      LEGACY_MODES.each do |mode|
        opt_name = "--legacy-#{mode.to_s.gsub('_', '-')}"
        opts.on opt_name, "Parse with legacy mode for emit_#{mode}" do
          @legacy[mode] = true
        end
      end

      opts.on '-w', '--warnings', 'Enable warnings' do |w|
        @warnings = w
      end

      opts.on '-B',  '--benchmark', 'Benchmark the processor' do |b|
        @benchmark = b
      end

      opts.on '-e fragment', 'Process a fragment of Ruby code' do |fragment|
        @fragments << fragment
      end
    end

    def parse_options(options)
      @option_parser.parse!(options)

      # Slop has just removed recognized options from `options`.
      @fragments << $stdin.read if options.delete('-')
      options.each do |file_or_dir|
        if File.directory?(file_or_dir)
          Find.find(file_or_dir) do |path|
            @files << path if path.end_with? '.rb'
          end
        else
          @files << file_or_dir
        end
      end

      if @files.empty? && @fragments.empty?
        $stderr.puts 'Need something to parse!'
        exit 1
      end

      if @parser_class.nil?
        require_relative 'current'
        @parser_class = Parser::CurrentRuby
      end
    end

    def setup_builder_default
      LEGACY_MODES.each do |mode|
        Parser::Builders::Default.send(:"emit_#{mode}=", !@legacy[mode])
      end
    end

    def prepare_parser
      @parser = @parser_class.new

      @parser.diagnostics.all_errors_are_fatal = true
      @parser.diagnostics.ignore_warnings      = !@warnings

      @parser.diagnostics.consumer = lambda do |diagnostic|
        puts(diagnostic.render)
      end
    end

    def input_size
      @files.size + @fragments.size
    end

    def process_all_input
      time_start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      process_fragments
      process_files
      time_elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - time_start

      if @benchmark
        report_with_time(time_elapsed)
      end
    end

    def process_fragments
      @fragments.each_with_index do |fragment, index|
        fragment = fragment.dup.force_encoding(@parser.default_encoding)

        buffer = Source::Buffer.new("(fragment:#{index})")
        buffer.source = fragment

        process_buffer(buffer)
      end
    end

    def process_files
      @files.each do |filename|
        source = begin
          File.read(filename).force_encoding(@parser.default_encoding)
        rescue Errno::EISDIR
          # Will happen for a folder called `foo.rb`. Just catch this here, it's cheaper than checking every file.
          next
        end

        buffer = Parser::Source::Buffer.new(filename)

        if @parser.class.name == 'Parser::Ruby18'
          buffer.raw_source = source
        else
          buffer.source     = source
        end

        process_buffer(buffer)
      end
    end

    def process_buffer(buffer)
      @parser.reset

      process(buffer)

      @source_count += 1
      @source_size  += buffer.source.size

    rescue Parser::SyntaxError
      # skip

    rescue StandardError
      $stderr.puts("Failed on: #{buffer.name}")
      raise
    end

    def process(buffer)
      raise NotImplementedError, "implement #{self.class}##{__callee__}"
    end

    def report_with_time(time_elapsed)
      speed = '%.3f' % (@source_size / time_elapsed / 1000)
      puts "Parsed #{@source_count} files (#{@source_size} characters)" \
           " in #{'%.2f' % time_elapsed} seconds (#{speed} kchars/s)."

      if defined?(RUBY_ENGINE)
        engine = RUBY_ENGINE
      else
        engine = 'ruby'
      end

      puts "Running on #{engine} #{RUBY_VERSION}."
    end
  end

end
