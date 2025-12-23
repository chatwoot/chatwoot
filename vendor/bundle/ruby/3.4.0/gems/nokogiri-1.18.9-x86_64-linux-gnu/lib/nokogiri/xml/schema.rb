# frozen_string_literal: true

module Nokogiri
  module XML
    class << self
      # :call-seq:
      #   Schema(input) → Nokogiri::XML::Schema
      #   Schema(input, parse_options) → Nokogiri::XML::Schema
      #
      # Convenience method for Nokogiri::XML::Schema.new
      def Schema(...)
        Schema.new(...)
      end
    end

    # Nokogiri::XML::Schema is used for validating \XML against an \XSD schema definition.
    #
    # ⚠ Since v1.11.0, Schema treats inputs as *untrusted* by default, and so external entities are
    # not resolved from the network (+http://+ or +ftp://+). When parsing a trusted document, the
    # caller may turn off the +NONET+ option via the ParseOptions to (re-)enable external entity
    # resolution over a network connection.
    #
    # 🛡 Before v1.11.0, documents were "trusted" by default during schema parsing which was counter
    # to Nokogiri's "untrusted by default" security policy.
    #
    # *Example:* Determine whether an \XML document is valid.
    #
    #   schema = Nokogiri::XML::Schema.new(File.read(XSD_FILE))
    #   doc = Nokogiri::XML::Document.parse(File.read(XML_FILE))
    #   schema.valid?(doc) # Boolean
    #
    # *Example:* Validate an \XML document against an \XSD schema, and capture any errors that are found.
    #
    #   schema = Nokogiri::XML::Schema.new(File.read(XSD_FILE))
    #   doc = Nokogiri::XML::Document.parse(File.read(XML_FILE))
    #   errors = schema.validate(doc) # Array<SyntaxError>
    #
    # *Example:* Validate an \XML document using a Document containing an \XSD schema definition.
    #
    #   schema_doc = Nokogiri::XML::Document.parse(File.read(RELAX_NG_FILE))
    #   schema = Nokogiri::XML::Schema.from_document(schema_doc)
    #   doc = Nokogiri::XML::Document.parse(File.read(XML_FILE))
    #   schema.valid?(doc) # Boolean
    #
    class Schema
      # The errors found while parsing the \XSD
      #
      # [Returns] Array<Nokogiri::XML::SyntaxError>
      attr_accessor :errors

      # The options used to parse the schema
      #
      # [Returns] Nokogiri::XML::ParseOptions
      attr_accessor :parse_options

      # :call-seq:
      #   new(input) → Nokogiri::XML::Schema
      #   new(input, parse_options) → Nokogiri::XML::Schema
      #
      # Parse an \XSD schema definition from a String or IO to create a new Nokogiri::XML::Schema
      #
      # [Parameters]
      # - +input+ (String | IO) \XSD schema definition
      # - +parse_options+ (Nokogiri::XML::ParseOptions)
      #   Defaults to Nokogiri::XML::ParseOptions::DEFAULT_SCHEMA
      #
      # [Returns] Nokogiri::XML::Schema
      #
      def self.new(input, parse_options_ = ParseOptions::DEFAULT_SCHEMA, parse_options: parse_options_)
        from_document(Nokogiri::XML::Document.parse(input), parse_options)
      end

      # :call-seq:
      #   read_memory(input) → Nokogiri::XML::Schema
      #   read_memory(input, parse_options) → Nokogiri::XML::Schema
      #
      # Convenience method for Nokogiri::XML::Schema.new
      def self.read_memory(...)
        # TODO deprecate this method
        new(...)
      end

      #
      # :call-seq: validate(input) → Array<SyntaxError>
      #
      # Validate +input+ and return any errors that are found.
      #
      # [Parameters]
      # - +input+ (Nokogiri::XML::Document | String)
      #   A parsed document, or a string containing a local filename.
      #
      # [Returns] Array<SyntaxError>
      #
      # *Example:* Validate an existing XML::Document, and capture any errors that are found.
      #
      #   schema = Nokogiri::XML::Schema.new(File.read(XSD_FILE))
      #   errors = schema.validate(document)
      #
      # *Example:* Validate an \XML document on disk, and capture any errors that are found.
      #
      #   schema = Nokogiri::XML::Schema.new(File.read(XSD_FILE))
      #   errors = schema.validate("/path/to/file.xml")
      #
      def validate(input)
        if input.is_a?(Nokogiri::XML::Document)
          validate_document(input)
        elsif File.file?(input)
          validate_file(input)
        else
          raise ArgumentError, "Must provide Nokogiri::XML::Document or the name of an existing file"
        end
      end

      #
      # :call-seq: valid?(input) → Boolean
      #
      # Validate +input+ and return a Boolean indicating whether the document is valid
      #
      # [Parameters]
      # - +input+ (Nokogiri::XML::Document | String)
      #   A parsed document, or a string containing a local filename.
      #
      # [Returns] Boolean
      #
      # *Example:* Validate an existing XML::Document
      #
      #   schema = Nokogiri::XML::Schema.new(File.read(XSD_FILE))
      #   return unless schema.valid?(document)
      #
      # *Example:* Validate an \XML document on disk
      #
      #   schema = Nokogiri::XML::Schema.new(File.read(XSD_FILE))
      #   return unless schema.valid?("/path/to/file.xml")
      #
      def valid?(input)
        validate(input).empty?
      end
    end
  end
end
