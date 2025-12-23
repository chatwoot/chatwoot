# encoding: ascii-8bit
# frozen_string_literal: true

module Parser
  module Source

    ##
    # A buffer with source code. {Buffer} contains the source code itself,
    # associated location information (name and first line), and takes care
    # of encoding.
    #
    # A source buffer is immutable once populated.
    #
    # @!attribute [r] name
    #  Buffer name. If the buffer was created from a file, the name corresponds
    #  to relative path to the file.
    #  @return [String] buffer name
    #
    # @!attribute [r] first_line
    #  First line of the buffer, 1 by default.
    #  @return [Integer] first line
    #
    # @api public
    #
    class Buffer
      attr_reader :name, :first_line

      ##
      # @api private
      #
      ENCODING_RE =
        /[\s#](en)?coding\s*[:=]\s*
          (
            # Special-case: there's a UTF8-MAC encoding.
            (utf8-mac)
          |
            # Chew the suffix; it's there for emacs compat.
            ([A-Za-z0-9_-]+?)(-unix|-dos|-mac)
          |
            ([A-Za-z0-9_-]+)
          )
        /x

      ##
      # Try to recognize encoding of `string` as Ruby would, i.e. by looking for
      # magic encoding comment or UTF-8 BOM. `string` can be in any encoding.
      #
      # @param [String]  string
      # @raise [Parser::UnknownEncodingInMagicComment] if the encoding is not recognized
      # @return [String, nil] encoding name, if recognized
      #
      def self.recognize_encoding(string)
        return if string.empty?

        # extract the first two lines in an efficient way
        string =~ /\A(.*)\n?(.*\n)?/
        first_line, second_line = $1, $2

        if first_line.start_with?("\xef\xbb\xbf".freeze) # BOM
          return Encoding::UTF_8
        elsif first_line[0, 2] == '#!'.freeze
          encoding_line = second_line
        else
          encoding_line = first_line
        end

        return nil if encoding_line.nil? || encoding_line[0] != '#'

        if (result = ENCODING_RE.match(encoding_line))
          begin
            Encoding.find(result[3] || result[4] || result[6])
          rescue ArgumentError => e
            raise Parser::UnknownEncodingInMagicComment, e.message
          end
        else
          nil
        end
      end

      ##
      # Recognize encoding of `input` and process it so it could be lexed.
      #
      #  * If `input` does not contain BOM or magic encoding comment, it is
      #    kept in the original encoding.
      #  * If the detected encoding is binary, `input` is kept in binary.
      #  * Otherwise, `input` is re-encoded into UTF-8 and returned as a
      #    new string.
      #
      # This method mutates the encoding of `input`, but not its content.
      #
      # @param  [String] input
      # @return [String]
      # @raise  [EncodingError]
      #
      def self.reencode_string(input)
        original_encoding = input.encoding
        detected_encoding = recognize_encoding(input.force_encoding(Encoding::BINARY))

        if detected_encoding.nil?
          input.force_encoding(original_encoding)
        elsif detected_encoding == Encoding::BINARY
          input
        else
          input.
            force_encoding(detected_encoding).
            encode(Encoding::UTF_8)
        end
      end

      def initialize(name, first_line = 1, source: nil)
        @name        = name.to_s
        @source      = nil
        @first_line  = first_line

        @lines       = nil
        @line_begins = nil

        # UTF-32-reencoded source for O(1) slicing
        @slice_source = nil

        # Cache for fast lookup
        @line_index_for_position = {}

        self.source = source if source
      end

      ##
      # Populate this buffer from correspondingly named file.
      #
      # @example
      #  Parser::Source::Buffer.new('foo/bar.rb').read
      #
      # @return [Buffer] self
      # @raise  [ArgumentError] if already populated
      #
      def read
        File.open(@name, 'rb') do |io|
          self.source = io.read
        end

        self
      end

      ##
      # Source code contained in this buffer.
      #
      # @return [String] source code
      # @raise  [RuntimeError] if buffer is not populated yet
      #
      def source
        if @source.nil?
          raise RuntimeError, 'Cannot extract source from uninitialized Source::Buffer'
        end

        @source
      end

      ##
      # Populate this buffer from a string with encoding autodetection.
      # `input` is mutated if not frozen.
      #
      # @param [String] input
      # @raise [ArgumentError] if already populated
      # @raise [EncodingError] if `input` includes invalid byte sequence for the encoding
      # @return [String]
      #
      def source=(input)
        input = input.dup if input.frozen?
        input = self.class.reencode_string(input)

        unless input.valid_encoding?
          raise EncodingError, "invalid byte sequence in #{input.encoding.name}"
        end

        self.raw_source = input
      end

      ##
      # Populate this buffer from a string without encoding autodetection.
      #
      # @param [String] input
      # @raise [ArgumentError] if already populated
      # @return [String]
      #
      def raw_source=(input)
        if @source
          raise ArgumentError, 'Source::Buffer is immutable'
        end

        @source = input.gsub("\r\n".freeze, "\n".freeze).freeze

        if !@source.ascii_only? &&
           @source.encoding != Encoding::UTF_32LE &&
           @source.encoding != Encoding::BINARY
          @slice_source = @source.encode(Encoding::UTF_32LE)
        end
      end

      def slice(start, length = nil)
        if length.nil?
          if start.is_a?(::Range)
            length = start.size
            start = start.begin
          else
            length = 1
          end
        end

        if @slice_source.nil?
          @source[start, length]
        else
          @slice_source[start, length].encode(@source.encoding)
        end
      end

      ##
      # Convert a character index into the source to a `[line, column]` tuple.
      #
      # @param  [Integer] position
      # @return [[Integer, Integer]] `[line, column]`
      #
      def decompose_position(position)
        line_index = line_index_for_position(position)
        line_begin = line_begins[line_index]

        [ @first_line + line_index , position - line_begin ]
      end

      ##
      # Convert a character index into the source to a line number.
      #
      # @param  [Integer] position
      # @return [Integer] line
      # @api private
      #
      def line_for_position(position)
        line_index_for_position(position) + @first_line
      end

      ##
      # Convert a character index into the source to a column number.
      #
      # @param  [Integer] position
      # @return [Integer] column
      # @api private
      #
      def column_for_position(position)
        line_index = line_index_for_position(position)
        position - line_begins[line_index]
      end

      ##
      # Return an `Array` of source code lines.
      #
      # @return [Array<String>]
      #
      def source_lines
        @lines ||= begin
          lines = @source.lines.to_a
          lines << ''.dup if @source.end_with?("\n".freeze)

          lines.each do |line|
            line.chomp!("\n".freeze)
            line.freeze
          end

          lines.freeze
        end
      end

      ##
      # Extract line `lineno` from source, taking `first_line` into account.
      #
      # @param  [Integer] lineno
      # @return [String]
      # @raise  [IndexError] if `lineno` is out of bounds
      #
      def source_line(lineno)
        source_lines.fetch(lineno - @first_line).dup
      end

      ##
      # Extract line `lineno` as a new `Range`, taking `first_line` into account.
      #
      # @param  [Integer] lineno
      # @return [Range]
      # @raise  [IndexError] if `lineno` is out of bounds
      #
      def line_range(lineno)
        index = lineno - @first_line
        if index < 0 || index + 1 >= line_begins.size
          raise IndexError, 'Parser::Source::Buffer: range for line ' \
            "#{lineno} requested, valid line numbers are #{@first_line}.." \
            "#{@first_line + line_begins.size - 2}"
        else
          Range.new(self, line_begins[index], line_begins[index + 1] - 1)
        end
      end

      ##
      # @return [Range] A range covering the whole source
      #
      def source_range
        @source_range ||= Range.new(self, 0, source.size)
      end

      ##
      # Number of last line in the buffer
      #
      # @return [Integer]
      #
      def last_line
        line_begins.size + @first_line - 2
      end

      # :nodoc:
      def freeze
        source_lines; line_begins; source_range # build cache
        super
      end

      # :nodoc:
      def inspect
        "#<#{self.class} #{name}>"
      end

      private

      # @returns [0, line_begin_of_line_1, ..., source.size + 1]
      def line_begins
        @line_begins ||= begin
          begins = [0]
          index = 0
          while index = @source.index("\n".freeze, index)
            index += 1
            begins << index
          end
          begins << @source.size + 1
          begins
        end
      end

      # @returns 0-based line index of position
      def line_index_for_position(position)
        @line_index_for_position[position] || begin
          index = bsearch(line_begins, position) - 1
          @line_index_for_position[position] = index unless @line_index_for_position.frozen?
          index
        end
      end

      if Array.method_defined?(:bsearch_index) # RUBY_VERSION >= 2.3
        def bsearch(line_begins, position)
          line_begins.bsearch_index do |line_begin|
            position < line_begin
          end || line_begins.size - 1 # || only for out of bound values
        end
      else
        def bsearch(line_begins, position)
          @line_range ||= 0...line_begins.size
          @line_range.bsearch do |i|
            position < line_begins[i]
          end || line_begins.size - 1 # || only for out of bound values
        end
      end
    end

  end
end
