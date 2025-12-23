# coding: US-ASCII
# frozen_string_literal: false

require "stringio"
require "strscan"

require_relative 'encoding'

module REXML
  if StringScanner::Version < "1.0.0"
    module StringScannerCheckScanString
      refine StringScanner do
        def check(pattern)
          pattern = /#{Regexp.escape(pattern)}/ if pattern.is_a?(String)
          super(pattern)
        end

        def scan(pattern)
          pattern = /#{Regexp.escape(pattern)}/ if pattern.is_a?(String)
          super(pattern)
        end

        def match?(pattern)
          pattern = /#{Regexp.escape(pattern)}/ if pattern.is_a?(String)
          super(pattern)
        end

        def skip(pattern)
          pattern = /#{Regexp.escape(pattern)}/ if pattern.is_a?(String)
          super(pattern)
        end
      end
    end
    using StringScannerCheckScanString
  end

  # Generates Source-s.  USE THIS CLASS.
  class SourceFactory
    # Generates a Source object
    # @param arg Either a String, or an IO
    # @return a Source, or nil if a bad argument was given
    def SourceFactory::create_from(arg)
      if arg.respond_to? :read and
          arg.respond_to? :readline and
          arg.respond_to? :nil? and
          arg.respond_to? :eof?
        IOSource.new(arg)
      elsif arg.respond_to? :to_str
        IOSource.new(StringIO.new(arg))
      elsif arg.kind_of? Source
        arg
      else
        raise "#{arg.class} is not a valid input stream.  It must walk \n"+
          "like either a String, an IO, or a Source."
      end
    end
  end

  # A Source can be searched for patterns, and wraps buffers and other
  # objects and provides consumption of text
  class Source
    include Encoding
    # The line number of the last consumed text
    attr_reader :line
    attr_reader :encoding

    module Private
      SPACES_PATTERN = /\s+/um
      SCANNER_RESET_SIZE = 100000
      PRE_DEFINED_TERM_PATTERNS = {}
      pre_defined_terms = ["'", '"', "<", "]]>", "?>"]
      if StringScanner::Version < "3.1.1"
        pre_defined_terms.each do |term|
          PRE_DEFINED_TERM_PATTERNS[term] = /#{Regexp.escape(term)}/
        end
      else
        pre_defined_terms.each do |term|
          PRE_DEFINED_TERM_PATTERNS[term] = term
        end
      end
    end
    private_constant :Private

    # Constructor
    # @param arg must be a String, and should be a valid XML document
    # @param encoding if non-null, sets the encoding of the source to this
    # value, overriding all encoding detection
    def initialize(arg, encoding=nil)
      @orig = arg
      @scanner = StringScanner.new(@orig)
      if encoding
        self.encoding = encoding
      else
        detect_encoding
      end
      @line = 0
      @encoded_terms = {}
    end

    # The current buffer (what we're going to read next)
    def buffer
      @scanner.rest
    end

    def drop_parsed_content
      if @scanner.pos > Private::SCANNER_RESET_SIZE
        @scanner.string = @scanner.rest
      end
    end

    def buffer_encoding=(encoding)
      @scanner.string.force_encoding(encoding)
    end

    # Inherited from Encoding
    # Overridden to support optimized en/decoding
    def encoding=(enc)
      return unless super
      encoding_updated
    end

    def read(term = nil)
    end

    def read_until(term)
      pattern = Private::PRE_DEFINED_TERM_PATTERNS[term] || /#{Regexp.escape(term)}/
      data = @scanner.scan_until(pattern)
      unless data
        data = @scanner.rest
        @scanner.pos = @scanner.string.bytesize
      end
      data
    end

    def ensure_buffer
    end

    def match(pattern, cons=false)
      if cons
        @scanner.scan(pattern).nil? ? nil : @scanner
      else
        @scanner.check(pattern).nil? ? nil : @scanner
      end
    end

    def match?(pattern, cons=false)
      if cons
        !@scanner.skip(pattern).nil?
      else
        !@scanner.match?(pattern).nil?
      end
    end

    def skip_spaces
      @scanner.skip(Private::SPACES_PATTERN) ? true : false
    end

    def position
      @scanner.pos
    end

    def position=(pos)
      @scanner.pos = pos
    end

    def peek_byte
      @scanner.peek_byte
    end

    def scan_byte
      @scanner.scan_byte
    end

    # @return true if the Source is exhausted
    def empty?
      @scanner.eos?
    end

    # @return the current line in the source
    def current_line
      lines = @orig.split
      res = lines.grep @scanner.rest[0..30]
      res = res[-1] if res.kind_of? Array
      lines.index( res ) if res
    end

    private

    def detect_encoding
      scanner_encoding = @scanner.rest.encoding
      detected_encoding = "UTF-8"
      begin
        @scanner.string.force_encoding("ASCII-8BIT")
        if @scanner.scan(/\xfe\xff/n)
          detected_encoding = "UTF-16BE"
        elsif @scanner.scan(/\xff\xfe/n)
          detected_encoding = "UTF-16LE"
        elsif @scanner.scan(/\xef\xbb\xbf/n)
          detected_encoding = "UTF-8"
        end
      ensure
        @scanner.string.force_encoding(scanner_encoding)
      end
      self.encoding = detected_encoding
    end

    def encoding_updated
      if @encoding != 'UTF-8'
        @scanner.string = decode(@scanner.rest)
        @to_utf = true
      else
        @to_utf = false
        @scanner.string.force_encoding(::Encoding::UTF_8)
      end
    end
  end

  # A Source that wraps an IO.  See the Source class for method
  # documentation
  class IOSource < Source
    #attr_reader :block_size

    # block_size has been deprecated
    def initialize(arg, block_size=500, encoding=nil)
      @er_source = @source = arg
      @to_utf = false
      @pending_buffer = nil

      if encoding
        super("", encoding)
      else
        super(@source.read(3) || "")
      end

      if !@to_utf and
          @orig.respond_to?(:force_encoding) and
          @source.respond_to?(:external_encoding) and
          @source.external_encoding != ::Encoding::UTF_8
        @force_utf8 = true
      else
        @force_utf8 = false
      end
    end

    def read(term = nil, min_bytes = 1)
      term = encode(term) if term
      begin
        str = readline(term)
        @scanner << str
        read_bytes = str.bytesize
        begin
          while read_bytes < min_bytes
            str = readline(term)
            @scanner << str
            read_bytes += str.bytesize
          end
        rescue IOError
        end
        true
      rescue Exception, NameError
        @source = nil
        false
      end
    end

    def read_until(term)
      pattern = Private::PRE_DEFINED_TERM_PATTERNS[term] || /#{Regexp.escape(term)}/
      term = @encoded_terms[term] ||= encode(term)
      until str = @scanner.scan_until(pattern)
        break if @source.nil?
        break if @source.eof?
        @scanner << readline(term)
      end
      if str
        read if @scanner.eos? and @source and !@source.eof?
        str
      else
        rest = @scanner.rest
        @scanner.pos = @scanner.string.bytesize
        rest
      end
    end

    def ensure_buffer
      read if @scanner.eos? && @source
    end

    def match( pattern, cons=false )
      # To avoid performance issue, we need to increase bytes to read per scan
      min_bytes = 1
      while true
        if cons
          md = @scanner.scan(pattern)
        else
          md = @scanner.check(pattern)
        end
        break if md
        return nil if pattern.is_a?(String)
        return nil if @source.nil?
        return nil unless read(nil, min_bytes)
        min_bytes *= 2
      end

      md.nil? ? nil : @scanner
    end

    def match?( pattern, cons=false )
      # To avoid performance issue, we need to increase bytes to read per scan
      min_bytes = 1
      while true
        if cons
          n_matched_bytes = @scanner.skip(pattern)
        else
          n_matched_bytes = @scanner.match?(pattern)
        end
        return true if n_matched_bytes
        return false if pattern.is_a?(String)
        return false if @source.nil?
        return false unless read(nil, min_bytes)
        min_bytes *= 2
      end
    end

    def empty?
      super and ( @source.nil? || @source.eof? )
    end

    # @return the current line in the source
    def current_line
      begin
        pos = @er_source.pos        # The byte position in the source
        lineno = @er_source.lineno  # The XML < position in the source
        @er_source.rewind
        line = 0                    # The \r\n position in the source
        begin
          while @er_source.pos < pos
            @er_source.readline
            line += 1
          end
        rescue
        end
        @er_source.seek(pos)
      rescue IOError, SystemCallError
        pos = -1
        line = -1
      end
      [pos, lineno, line]
    end

    private
    def readline(term = nil)
      if @pending_buffer
        begin
          str = @source.readline(term || @line_break)
        rescue IOError
        end
        if str.nil?
          str = @pending_buffer
        else
          str = @pending_buffer + str
        end
        @pending_buffer = nil
      else
        str = @source.readline(term || @line_break)
      end
      return nil if str.nil?

      if @to_utf
        decode(str)
      else
        str.force_encoding(::Encoding::UTF_8) if @force_utf8
        str
      end
    end

    def encoding_updated
      case @encoding
      when "UTF-16BE", "UTF-16LE"
        @source.binmode
        @source.set_encoding(@encoding, @encoding)
      end
      @line_break = encode(">")
      @pending_buffer, @scanner.string = @scanner.rest, ""
      @pending_buffer.force_encoding(@encoding)
      super
    end
  end
end
