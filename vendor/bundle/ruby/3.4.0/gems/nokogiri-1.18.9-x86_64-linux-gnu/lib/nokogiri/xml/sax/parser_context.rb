# frozen_string_literal: true

module Nokogiri
  module XML
    module SAX
      ###
      # Context object to invoke the XML SAX parser on the SAX::Document handler.
      #
      # 💡 This class is usually not instantiated by the user. Use Nokogiri::XML::SAX::Parser
      # instead.
      class ParserContext
        class << self
          ###
          # :call-seq:
          #   new(input)
          #   new(input, encoding)
          #
          # Create a parser context for an IO or a String. This is a shorthand method for
          # ParserContext.io and ParserContext.memory.
          #
          # [Parameters]
          # - +input+ (IO, String) A String or a readable IO object
          # - +encoding+ (optional) (Encoding) The +Encoding+ to use, or the name of an
          #   encoding to use (default +nil+, encoding will be autodetected)
          #
          # If +input+ quacks like a readable IO object, this method forwards to ParserContext.io,
          # otherwise it forwards to ParserContext.memory.
          #
          # [Returns] Nokogiri::XML::SAX::ParserContext
          #
          def new(input, encoding = nil)
            if [:read, :close].all? { |x| input.respond_to?(x) }
              io(input, encoding)
            else
              memory(input, encoding)
            end
          end

          ###
          # :call-seq:
          #   io(input)
          #   io(input, encoding)
          #
          # Create a parser context for an +input+ IO which will assume +encoding+
          #
          # [Parameters]
          # - +io+ (IO) The readable IO object from which to read input
          # - +encoding+ (optional) (Encoding) The +Encoding+ to use, or the name of an
          #   encoding to use (default +nil+, encoding will be autodetected)
          #
          # [Returns] Nokogiri::XML::SAX::ParserContext
          #
          # 💡 Calling this method directly is discouraged. Use Nokogiri::XML::SAX::Parser parse
          # methods which are more convenient for most use cases.
          #
          def io(input, encoding = nil)
            native_io(input, resolve_encoding(encoding))
          end

          ###
          # :call-seq:
          #   memory(input)
          #   memory(input, encoding)
          #
          # Create a parser context for the +input+ String.
          #
          # [Parameters]
          # - +input+ (String) The input string to be parsed.
          # - +encoding+ (optional) (Encoding, String) The +Encoding+ to use, or the name of an encoding to
          #   use (default +nil+, encoding will be autodetected)
          #
          # [Returns] Nokogiri::XML::SAX::ParserContext
          #
          # 💡 Calling this method directly is discouraged. Use Nokogiri::XML::SAX::Parser parse methods
          # which are more convenient for most use cases.
          #
          def memory(input, encoding = nil)
            native_memory(input, resolve_encoding(encoding))
          end

          ###
          # :call-seq:
          #   file(path)
          #   file(path, encoding)
          #
          # Create a parser context for the file at +path+.
          #
          # [Parameters]
          # - +path+ (String) The path to the input file
          # - +encoding+ (optional) (Encoding, String) The +Encoding+ to use, or the name of an encoding to
          #   use (default +nil+, encoding will be autodetected)
          #
          # [Returns] Nokogiri::XML::SAX::ParserContext
          #
          # 💡 Calling this method directly is discouraged. Use Nokogiri::XML::SAX::Parser.parse_file which
          # is more convenient for most use cases.
          def file(input, encoding = nil)
            native_file(input, resolve_encoding(encoding))
          end

          private def resolve_encoding(encoding)
            case encoding
            when Encoding
              encoding

            when nil
              nil # totally fine, parser will guess encoding

            when Integer
              warn("Passing an integer to Nokogiri::XML::SAX::ParserContext.io is deprecated. Use an Encoding object instead. This will become an error in a future release.", uplevel: 2, category: :deprecated)

              return nil if encoding == Parser::ENCODINGS["NONE"]

              encoding = Parser::REVERSE_ENCODINGS[encoding]
              raise ArgumentError, "Invalid libxml2 encoding id #{encoding}" if encoding.nil?
              Encoding.find(encoding)

            when String
              Encoding.find(encoding)

            else
              raise ArgumentError, "Cannot resolve #{encoding.inspect} to an Encoding"
            end
          end
        end
      end
    end
  end
end
