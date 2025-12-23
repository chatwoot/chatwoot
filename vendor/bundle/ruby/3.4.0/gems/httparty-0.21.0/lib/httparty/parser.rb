# frozen_string_literal: true

module HTTParty
  # The default parser used by HTTParty, supports xml, json, html, csv and
  # plain text.
  #
  # == Custom Parsers
  #
  # If you'd like to do your own custom parsing, subclassing HTTParty::Parser
  # will make that process much easier. There are a few different ways you can
  # utilize HTTParty::Parser as a superclass.
  #
  # @example Intercept the parsing for all formats
  #   class SimpleParser < HTTParty::Parser
  #     def parse
  #       perform_parsing
  #     end
  #   end
  #
  # @example Add the atom format and parsing method to the default parser
  #   class AtomParsingIncluded < HTTParty::Parser
  #     SupportedFormats.merge!(
  #       {"application/atom+xml" => :atom}
  #     )
  #
  #     def atom
  #       perform_atom_parsing
  #     end
  #   end
  #
  # @example Only support the atom format
  #   class ParseOnlyAtom < HTTParty::Parser
  #     SupportedFormats = {"application/atom+xml" => :atom}
  #
  #     def atom
  #       perform_atom_parsing
  #     end
  #   end
  #
  # @abstract Read the Custom Parsers section for more information.
  class Parser
    SupportedFormats = {
      'text/xml'                    => :xml,
      'application/xml'             => :xml,
      'application/json'            => :json,
      'application/vnd.api+json'    => :json,
      'application/hal+json'        => :json,
      'text/json'                   => :json,
      'application/javascript'      => :plain,
      'text/javascript'             => :plain,
      'text/html'                   => :html,
      'text/plain'                  => :plain,
      'text/csv'                    => :csv,
      'application/csv'             => :csv,
      'text/comma-separated-values' => :csv
    }

    # The response body of the request
    # @return [String]
    attr_reader :body

    # The intended parsing format for the request
    # @return [Symbol] e.g. :json
    attr_reader :format

    # Instantiate the parser and call {#parse}.
    # @param [String] body the response body
    # @param [Symbol] format the response format
    # @return parsed response
    def self.call(body, format)
      new(body, format).parse
    end

    # @return [Hash] the SupportedFormats hash
    def self.formats
      const_get(:SupportedFormats)
    end

    # @param [String] mimetype response MIME type
    # @return [Symbol]
    # @return [nil] mime type not supported
    def self.format_from_mimetype(mimetype)
      formats[formats.keys.detect {|k| mimetype.include?(k)}]
    end

    # @return [Array<Symbol>] list of supported formats
    def self.supported_formats
      formats.values.uniq
    end

    # @param [Symbol] format e.g. :json, :xml
    # @return [Boolean]
    def self.supports_format?(format)
      supported_formats.include?(format)
    end

    def initialize(body, format)
      @body = body
      @format = format
    end

    # @return [Object] the parsed body
    # @return [nil] when the response body is nil, an empty string, spaces only or "null"
    def parse
      return nil if body.nil?
      return nil if body == 'null'
      return nil if body.valid_encoding? && body.strip.empty?
      if body.valid_encoding? && body.encoding == Encoding::UTF_8
        @body = body.gsub(/\A#{UTF8_BOM}/, '')
      end
      if supports_format?
        parse_supported_format
      else
        body
      end
    end

    protected

    def xml
      MultiXml.parse(body)
    end

    UTF8_BOM = "\xEF\xBB\xBF"

    def json
      JSON.parse(body, :quirks_mode => true, :allow_nan => true)
    end

    def csv
      CSV.parse(body)
    end

    def html
      body
    end

    def plain
      body
    end

    def supports_format?
      self.class.supports_format?(format)
    end

    def parse_supported_format
      if respond_to?(format, true)
        send(format)
      else
        raise NotImplementedError, "#{self.class.name} has not implemented a parsing method for the #{format.inspect} format."
      end
    end
  end
end
