# frozen_string_literal: true

module Parser

  ##
  # @api public
  #
  # @!attribute [r] level
  #  @see LEVELS
  #  @return [Symbol] diagnostic level
  #
  # @!attribute [r] reason
  #  @see Parser::MESSAGES
  #  @return [Symbol] reason for error
  #
  # @!attribute [r] arguments
  #  @see Parser::MESSAGES
  #  @return [Symbol] extended arguments that describe the error
  #
  # @!attribute [r] message
  #  @return [String] error message
  #
  # @!attribute [r] location
  #  Main error-related source range.
  #  @return [Parser::Source::Range]
  #
  # @!attribute [r] highlights
  #  Supplementary error-related source ranges.
  #  @return [Array<Parser::Source::Range>]
  #
  class Diagnostic
    ##
    # Collection of the available diagnostic levels.
    #
    # @return [Array]
    #
    LEVELS = [:note, :warning, :error, :fatal].freeze

    attr_reader :level, :reason, :arguments
    attr_reader :location, :highlights

    ##
    # @param [Symbol] level
    # @param [Symbol] reason
    # @param [Hash] arguments
    # @param [Parser::Source::Range] location
    # @param [Array<Parser::Source::Range>] highlights
    #
    def initialize(level, reason, arguments, location, highlights=[])
      unless LEVELS.include?(level)
        raise ArgumentError,
              "Diagnostic#level must be one of #{LEVELS.join(', ')}; " \
              "#{level.inspect} provided."
      end
      raise 'Expected a location' unless location

      @level       = level
      @reason      = reason
      @arguments   = (arguments || {}).dup.freeze
      @location    = location
      @highlights  = highlights.dup.freeze

      freeze
    end

    ##
    # @return [String] the rendered message.
    #
    def message
      Messages.compile(@reason, @arguments)
    end

    ##
    # Renders the diagnostic message as a clang-like diagnostic.
    #
    # @example
    #  diagnostic.render # =>
    #  # [
    #  #   "(fragment:0):1:5: error: unexpected token $end",
    #  #   "foo +",
    #  #   "    ^"
    #  # ]
    #
    # @return [Array<String>]
    #
    def render
      if @location.line == @location.last_line || @location.is?("\n")
        ["#{@location}: #{@level}: #{message}"] + render_line(@location)
      else
        # multi-line diagnostic
        first_line = first_line_only(@location)
        last_line  = last_line_only(@location)
        num_lines  = (@location.last_line - @location.line) + 1
        buffer     = @location.source_buffer

        last_lineno, last_column = buffer.decompose_position(@location.end_pos)
        ["#{@location}-#{last_lineno}:#{last_column}: #{@level}: #{message}"] +
          render_line(first_line, num_lines > 2, false) +
          render_line(last_line, false, true)
      end
    end

    private

    ##
    # Renders one source line in clang diagnostic style, with highlights.
    #
    # @return [Array<String>]
    #
    def render_line(range, ellipsis=false, range_end=false)
      source_line    = range.source_line
      highlight_line = ' ' * source_line.length

      @highlights.each do |highlight|
       line_range = range.source_buffer.line_range(range.line)
        if highlight = highlight.intersect(line_range)
          highlight_line[highlight.column_range] = '~' * highlight.size
        end
      end

      if range.is?("\n")
        highlight_line += "^"
      else
        if !range_end && range.size >= 1
          highlight_line[range.column_range] = '^' + '~' * (range.size - 1)
        else
          highlight_line[range.column_range] = '~' * range.size
        end
      end

      highlight_line += '...' if ellipsis

      [source_line, highlight_line].
        map { |line| "#{range.source_buffer.name}:#{range.line}: #{line}" }
    end

    ##
    # If necessary, shrink a `Range` so as to include only the first line.
    #
    # @return [Parser::Source::Range]
    #
    def first_line_only(range)
      if range.line != range.last_line
        range.resize(range.source =~ /\n/)
      else
        range
      end
    end

    ##
    # If necessary, shrink a `Range` so as to include only the last line.
    #
    # @return [Parser::Source::Range]
    #
    def last_line_only(range)
      if range.line != range.last_line
        range.adjust(begin_pos: range.source =~ /[^\n]*\z/)
      else
        range
      end
    end
  end
end
