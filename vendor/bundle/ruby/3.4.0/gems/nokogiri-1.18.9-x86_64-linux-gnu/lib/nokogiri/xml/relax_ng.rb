# frozen_string_literal: true

module Nokogiri
  module XML
    class << self
      # :call-seq:
      #   RelaxNG(input) → Nokogiri::XML::RelaxNG
      #   RelaxNG(input, options:) → Nokogiri::XML::RelaxNG
      #
      # Convenience method for Nokogiri::XML::RelaxNG.new
      def RelaxNG(...)
        RelaxNG.new(...)
      end
    end

    # Nokogiri::XML::RelaxNG is used for validating \XML against a RELAX NG schema definition.
    #
    # 🛡 <b>Do not use this class for untrusted schema documents.</b> RELAX NG input is always
    # treated as *trusted*, meaning that the underlying parsing libraries <b>will access network
    # resources</b>. This is counter to Nokogiri's "untrusted by default" security policy, but is an
    # unfortunate limitation of the underlying libraries.
    #
    # *Example:* Determine whether an \XML document is valid.
    #
    #   schema = Nokogiri::XML::RelaxNG.new(File.read(RELAX_NG_FILE))
    #   doc = Nokogiri::XML::Document.parse(File.read(XML_FILE))
    #   schema.valid?(doc) # Boolean
    #
    # *Example:* Validate an \XML document against a \RelaxNG schema, and capture any errors that are found.
    #
    #   schema = Nokogiri::XML::RelaxNG.new(File.open(RELAX_NG_FILE))
    #   doc = Nokogiri::XML::Document.parse(File.open(XML_FILE))
    #   errors = schema.validate(doc) # Array<SyntaxError>
    #
    # *Example:* Validate an \XML document using a Document containing a RELAX NG schema definition.
    #
    #   schema_doc = Nokogiri::XML::Document.parse(File.read(RELAX_NG_FILE))
    #   schema = Nokogiri::XML::RelaxNG.from_document(schema_doc)
    #   doc = Nokogiri::XML::Document.parse(File.open(XML_FILE))
    #   schema.valid?(doc) # Boolean
    #
    class RelaxNG < Nokogiri::XML::Schema
      # :call-seq:
      #   new(input) → Nokogiri::XML::RelaxNG
      #   new(input, options:) → Nokogiri::XML::RelaxNG
      #
      # Parse a RELAX NG schema definition from a String or IO to create a new Nokogiri::XML::RelaxNG.
      #
      # [Parameters]
      # - +input+ (String | IO) RELAX NG schema definition
      # - +options:+ (Nokogiri::XML::ParseOptions)
      #   Defaults to Nokogiri::XML::ParseOptions::DEFAULT_SCHEMA ⚠ Unused
      #
      # [Returns] Nokogiri::XML::RelaxNG
      #
      # ⚠ +parse_options+ is currently unused by this method and is present only as a placeholder for
      # future functionality.
      #
      # Also see convenience method Nokogiri::XML::RelaxNG()
      def self.new(input, parse_options_ = ParseOptions::DEFAULT_SCHEMA, options: parse_options_)
        from_document(Nokogiri::XML::Document.parse(input), options)
      end

      # :call-seq:
      #   read_memory(input) → Nokogiri::XML::RelaxNG
      #   read_memory(input, options:) → Nokogiri::XML::RelaxNG
      #
      # Convenience method for Nokogiri::XML::RelaxNG.new.
      def self.read_memory(...)
        # TODO deprecate this method
        new(...)
      end
    end
  end
end
