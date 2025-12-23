# frozen_string_literal: true

module Nokogiri
  module HTML4
    # Libxml2's parser has poor support for encoding detection.  First, it does not recognize the
    # HTML5 style meta charset declaration.  Secondly, even if it successfully detects an encoding
    # hint, it does not re-decode or re-parse the preceding part which may be garbled.
    #
    # EncodingReader aims to perform advanced encoding detection beyond what Libxml2 does, and to
    # emulate rewinding of a stream and make Libxml2 redo parsing from the start when an encoding
    # hint is found.

    # :nodoc: all
    class EncodingReader
      class EncodingFound < StandardError
        attr_reader :found_encoding

        def initialize(encoding)
          @found_encoding = encoding
          super(format("encoding found: %s", encoding))
        end
      end

      class SAXHandler < Nokogiri::XML::SAX::Document
        attr_reader :encoding

        def initialize
          @encoding = nil
          super
        end

        def start_element(name, attrs = [])
          return unless name == "meta"

          attr = Hash[attrs]
          (charset = attr["charset"]) &&
            (@encoding = charset)
          (http_equiv = attr["http-equiv"]) &&
            http_equiv.match(/\AContent-Type\z/i) &&
            (content = attr["content"]) &&
            (m = content.match(/;\s*charset\s*=\s*([\w-]+)/)) &&
            (@encoding = m[1])
        end
      end

      class JumpSAXHandler < SAXHandler
        def initialize(jumptag)
          @jumptag = jumptag
          super()
        end

        def start_element(name, attrs = [])
          super
          throw(@jumptag, @encoding) if @encoding
          throw(@jumptag, nil) if /\A(?:div|h1|img|p|br)\z/.match?(name)
        end
      end

      def self.detect_encoding(chunk)
        (m = chunk.match(/\A(<\?xml[ \t\r\n][^>]*>)/)) &&
          (return Nokogiri.XML(m[1]).encoding)

        if Nokogiri.jruby?
          (m = chunk.match(/(<meta\s)(.*)(charset\s*=\s*([\w-]+))(.*)/i)) &&
            (return m[4])
          catch(:encoding_found) do
            Nokogiri::HTML4::SAX::Parser.new(JumpSAXHandler.new(:encoding_found)).parse(chunk)
            nil
          end
        else
          handler = SAXHandler.new
          parser = Nokogiri::HTML4::SAX::PushParser.new(handler)
          begin
            parser << chunk
          rescue
            Nokogiri::SyntaxError
          end
          handler.encoding
        end
      end

      def initialize(io)
        @io = io
        @firstchunk = nil
        @encoding_found = nil
      end

      # This method is used by the C extension so that
      # Nokogiri::HTML4::Document#read_io() does not leak memory when
      # EncodingFound is raised.
      attr_reader :encoding_found

      def read(len)
        # no support for a call without len

        unless @firstchunk
          (@firstchunk = @io.read(len)) || return

          # This implementation expects that the first call from
          # htmlReadIO() is made with a length long enough (~1KB) to
          # achieve advanced encoding detection.
          if (encoding = EncodingReader.detect_encoding(@firstchunk))
            # The first chunk is stored for the next read in retry.
            raise @encoding_found = EncodingFound.new(encoding)
          end
        end
        @encoding_found = nil

        ret = @firstchunk.slice!(0, len)
        if (len -= ret.length) > 0
          (rest = @io.read(len)) && ret << (rest)
        end
        if ret.empty?
          nil
        else
          ret
        end
      end
    end
  end
end
