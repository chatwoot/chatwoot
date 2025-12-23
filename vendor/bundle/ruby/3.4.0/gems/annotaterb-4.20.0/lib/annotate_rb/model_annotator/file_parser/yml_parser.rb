# frozen_string_literal: true

require "psych"

module AnnotateRb
  module ModelAnnotator
    module FileParser
      class YmlParser
        class << self
          def parse(string)
            _parser = new(string).tap(&:parse)
          end
        end

        attr_reader :comments, :starts, :ends

        def initialize(input)
          @input = input
          @comments = []
          @starts = []
          @ends = []
        end

        def parse
          parse_comments
          parse_yml
        end

        private

        def parse_comments
          # Adds 0-indexed line numbers
          @input.split($/).each_with_index do |line, line_no|
            if line.strip.starts_with?("#")
              @comments << [line, line_no]
            end
          end
        end

        def parse_yml
          # https://docs.ruby-lang.org/en/master/Psych.html#module-Psych-label-Reading+to+Psych-3A-3ANodes-3A-3AStream+structure
          parser = Psych.parser
          begin
            parser.parse(@input)
          rescue Psych::SyntaxError => _e
            # "Dynamic fixtures with ERB" exist in Rails, and will cause Psych.parser to error
            # This is a hacky solution to get around this and still have it parse
            erb_yml = ERB.new(@input).result
            parser.parse(erb_yml)
          end

          stream = parser.handler.root

          if stream.children.any?
            doc = stream.children.first
            @starts << [nil, doc.start_line]
            @ends << [nil, doc.end_line]
          else
            # When parsing a yml file, streamer returns an instance of `Psych::Nodes::Stream` which is a subclass of
            #   `Psych::Nodes::Node`. It along with children nodes, implement #start_line and #end_line.
            #
            # When parsing input that is only comments, the parser counts #start_line as the start of the file being
            #   line 0.
            #
            # What we really want is where the "start" of the yml file would happen, which would be after comments.
            # This is stream#end_line.
            @starts << [nil, stream.end_line]
            @ends << [nil, stream.end_line]
          end
        end
      end
    end
  end
end
