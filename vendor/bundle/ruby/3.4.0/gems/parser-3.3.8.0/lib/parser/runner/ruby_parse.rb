# frozen_string_literal: true

require_relative '../runner'
require_relative '../color'
require_relative '../lexer/explanation'
require 'json'

module Parser

  class Runner::RubyParse < Parser::Runner

    class LocationProcessor < Parser::AST::Processor
      def process(node)
        if node
          p node

          source_line_no = nil
          source_line    = ''
          hilight_line   = ''

          print_line = lambda do
            unless hilight_line.empty?
              puts hilight_line.
                gsub(/[a-z_]+/) { |m| Color.yellow(m, bold: true) }.
                gsub(/[~.]+/)   { |m| Color.magenta(m, bold: true) }
              hilight_line = ''
            end
          end

          print_source = lambda do |range|
            source_line = range.source_line
            puts Color.green(source_line)
            source_line
          end

          (node.loc || {}).to_hash.
            sort_by do |name, range|
              [(range ? range.line : 0),
               (name == :expression ? 1 : 0)]
            end.
            each do |name, range|
              next if range.nil?

              if source_line_no != range.line
                print_line.call()
                source_line    = print_source.call(range)
                source_line_no = range.line
              end

              beg_col = range.begin.column

              if beg_col + range.length > source_line.length
                multiline    = true
                range_length = source_line.length - beg_col + 3
              else
                multiline    = false
                range_length = range.length
              end

              length  = range_length + 1 + name.length
              end_col = beg_col + length

              if beg_col > 0
                col_range = (beg_col - 1)...end_col
              else
                col_range = beg_col...end_col
              end

              if hilight_line.length < end_col
                hilight_line = hilight_line.ljust(end_col)
              end

              if hilight_line[col_range] =~ /^\s*$/
                if multiline
                  tail = ('~' * (source_line.length - beg_col)) + '...'
                else
                  tail = '~' * range_length
                end

                tail = ' ' + tail if beg_col > 0

                hilight_line[col_range] = tail + " #{name}"
              else
                print_line.call
                redo
              end
            end

          print_line.call
        end

        super
      end
    end

    def initialize
      super

      @locate = false
      @emit_ruby = false
      @emit_json = false
    end

    private

    def runner_name
      'ruby-parse'
    end

    def setup_option_parsing(opts)
      super(opts)

      opts.on '-L', '--locate', 'Explain how source maps for AST nodes are laid out' do |v|
        @locate = v
      end

      opts.on '-E', '--explain', 'Explain how the source is tokenized' do
        ENV['RACC_DEBUG'] = '1'

        Lexer.send :include, Lexer::Explanation
      end

      opts.on '--emit-ruby', 'Emit S-expressions as valid Ruby code' do
        @emit_ruby = true
      end

      opts.on '--emit-json', 'Emit S-expressions as valid JSON' do
        @emit_json = true
      end
    end

    def process_all_input
      if input_size > 1
        puts "Using #{@parser_class} to parse #{input_size} files."
      end

      super
    end

    def process(buffer)
      ast = @parser.parse(buffer)

      if @locate
        LocationProcessor.new.process(ast)
      elsif !@benchmark
        if @emit_ruby
          puts ast.inspect
        elsif @emit_json
          puts(ast ? JSON.generate(ast.to_sexp_array) : nil)
        else
          puts ast.to_s
        end
      end
    end
  end

end
