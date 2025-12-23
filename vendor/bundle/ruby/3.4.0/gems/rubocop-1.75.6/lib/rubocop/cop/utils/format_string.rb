# frozen_string_literal: true

module RuboCop
  module Cop
    module Utils
      # Parses {Kernel#sprintf} format strings.
      class FormatString
        # Escaping the `#` in `INTERPOLATION` and `TEMPLATE_NAME` is necessary to
        # avoid a bug in Ruby 3.2.0
        # See: https://bugs.ruby-lang.org/issues/19379
        DIGIT_DOLLAR  = /(?<arg_number>\d+)\$/.freeze
        INTERPOLATION = /\#\{.*?\}/.freeze
        FLAG          = /[ #0+-]|#{DIGIT_DOLLAR}/.freeze
        NUMBER_ARG    = /\*#{DIGIT_DOLLAR}?/.freeze
        NUMBER        = /\d+|#{NUMBER_ARG}|#{INTERPOLATION}/.freeze
        WIDTH         = /(?<width>#{NUMBER})/.freeze
        PRECISION     = /\.(?<precision>#{NUMBER}?)/.freeze
        TYPE          = /(?<type>[bBdiouxXeEfgGaAcps])/.freeze
        NAME          = /<(?<name>\w+)>/.freeze
        TEMPLATE_NAME = /(?<!\#)\{(?<name>\w+)\}/.freeze

        SEQUENCE = /
            % (?<type>%)
          | % (?<flags>#{FLAG}*)
            (?:
              (?: #{WIDTH}? #{PRECISION}? #{NAME}?
                | #{WIDTH}? #{NAME} #{PRECISION}?
                | #{NAME} (?<more_flags>#{FLAG}*) #{WIDTH}? #{PRECISION}?
              ) #{TYPE}
              | #{WIDTH}? #{PRECISION}? #{TEMPLATE_NAME}
            )
        /x.freeze

        # The syntax of a format sequence is as follows.
        #
        # ```
        # %[flags][width][.precision]type
        # ```
        #
        # A format sequence consists of a percent sign, followed by optional
        # flags, width, and precision indicators, then terminated with a field
        # type character.
        #
        # For more complex formatting, Ruby supports a reference by name.
        #
        # @see https://ruby-doc.org/core-2.6.3/Kernel.html#method-i-format
        class FormatSequence
          attr_reader :begin_pos, :end_pos, :flags, :width, :precision, :name, :type, :arg_number

          def initialize(match)
            @source = match[0]
            @begin_pos = match.begin(0)
            @end_pos = match.end(0)
            @flags = match[:flags].to_s + match[:more_flags].to_s
            @width = match[:width]
            @precision = match[:precision]
            @name = match[:name]
            @type = match[:type]
            @arg_number = match[:arg_number]
          end

          def percent?
            type == '%'
          end

          def annotated?
            name && @source.include?('<')
          end

          def template?
            name && @source.include?('{')
          end

          # Number of arguments required for the format sequence
          def arity
            @source.scan('*').count + 1
          end

          def max_digit_dollar_num
            @source.scan(DIGIT_DOLLAR).map { |(digit_dollar_num)| digit_dollar_num.to_i }.max
          end

          def style
            if annotated?
              :annotated
            elsif template?
              :template
            else
              :unannotated
            end
          end
        end

        def initialize(string)
          @source = string
        end

        def format_sequences
          @format_sequences ||= parse
        end

        def valid?
          !mixed_formats?
        end

        def named_interpolation?
          format_sequences.any?(&:name)
        end

        def max_digit_dollar_num
          format_sequences.map(&:max_digit_dollar_num).max
        end

        private

        def parse
          matches = []
          @source.scan(SEQUENCE) { matches << FormatSequence.new(Regexp.last_match) }
          matches
        end

        def mixed_formats?
          formats = format_sequences.reject(&:percent?).map do |seq|
            if seq.name
              :named
            elsif seq.max_digit_dollar_num
              :numbered
            else
              :unnumbered
            end
          end

          formats.uniq.size > 1
        end
      end
    end
  end
end
