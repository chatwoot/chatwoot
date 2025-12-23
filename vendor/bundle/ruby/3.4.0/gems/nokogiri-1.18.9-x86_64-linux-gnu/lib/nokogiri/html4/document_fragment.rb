# frozen_string_literal: true

module Nokogiri
  module HTML4
    class DocumentFragment < Nokogiri::XML::DocumentFragment
      #
      # :call-seq:
      #   parse(input) { |options| ... } → HTML4::DocumentFragment
      #   parse(input, encoding:, options:) { |options| ... } → HTML4::DocumentFragment
      #
      # Parse \HTML4 fragment input from a String, and return a new HTML4::DocumentFragment. This
      # method creates a new, empty HTML4::Document to contain the fragment.
      #
      # [Required Parameters]
      # - +input+ (String | IO) The content to be parsed.
      #
      # [Optional Keyword Arguments]
      # - +encoding:+ (String) The name of the encoding that should be used when processing the
      #   document. When not provided, the encoding will be determined based on the document
      #   content.
      #
      # - +options:+ (Nokogiri::XML::ParseOptions) Configuration object that determines some
      #   behaviors during parsing. See ParseOptions for more information. The default value is
      #   +ParseOptions::DEFAULT_HTML+.
      #
      # [Yields]
      #   If a block is given, a Nokogiri::XML::ParseOptions object is yielded to the block which
      #   can be configured before parsing. See ParseOptions for more information.
      #
      # [Returns] HTML4::DocumentFragment
      #
      # *Example:* Parsing a string
      #
      #   fragment = HTML4::DocumentFragment.parse("<div>Hello World</div>")
      #
      # *Example:* Parsing an IO
      #
      #   fragment = File.open("fragment.html") do |file|
      #     HTML4::DocumentFragment.parse(file)
      #   end
      #
      # *Example:* Specifying encoding
      #
      #   fragment = HTML4::DocumentFragment.parse(input, encoding: "EUC-JP")
      #
      # *Example:* Setting parse options dynamically
      #
      #   HTML4::DocumentFragment.parse("<div>Hello World") do |options|
      #     options.huge.pedantic
      #   end
      #
      def self.parse(
        input,
        encoding_ = nil, options_ = XML::ParseOptions::DEFAULT_HTML,
        encoding: encoding_, options: options_,
        &block
      )
        # TODO: this method should take a context node.
        doc = HTML4::Document.new

        if input.respond_to?(:read)
          # Handle IO-like objects (IO, File, StringIO, etc.)
          # The _read_ method of these objects doesn't accept an +encoding+ parameter.
          # Encoding is usually set when the IO object is created or opened,
          # or by using the _set_encoding_ method.
          #
          # 1. If +encoding+ is provided and the object supports _set_encoding_,
          #    set the encoding before reading.
          # 2. Read the content from the IO-like object.
          #
          # Note: After reading, the content's encoding will be:
          # - The encoding set by _set_encoding_ if it was called
          # - The default encoding of the IO object otherwise
          #
          # For StringIO specifically, _set_encoding_ affects only the internal string,
          # not how the data is read out.
          input.set_encoding(encoding) if encoding && input.respond_to?(:set_encoding)
          input = input.read
        end

        encoding ||= if input.respond_to?(:encoding)
          encoding = input.encoding
          if encoding == ::Encoding::ASCII_8BIT
            "UTF-8"
          else
            encoding.name
          end
        else
          "UTF-8"
        end

        doc.encoding = encoding

        new(doc, input, options: options, &block)
      end

      #
      # :call-seq:
      #   new(document) { |options| ... } → HTML4::DocumentFragment
      #   new(document, input) { |options| ... } → HTML4::DocumentFragment
      #   new(document, input, context:, options:) { |options| ... } → HTML4::DocumentFragment
      #
      # Parse \HTML4 fragment input from a String, and return a new HTML4::DocumentFragment.
      #
      # 💡 It's recommended to use either HTML4::DocumentFragment.parse or XML::Node#parse rather
      # than call this method directly.
      #
      # [Required Parameters]
      # - +document+ (HTML4::Document) The parent document to associate the returned fragment with.
      #
      # [Optional Parameters]
      # - +input+ (String) The content to be parsed.
      #
      # [Optional Keyword Arguments]
      # - +context:+ (Nokogiri::XML::Node) The <b>context node</b> for the subtree created. See
      #   below for more information.
      #
      # - +options:+ (Nokogiri::XML::ParseOptions) Configuration object that determines some
      #   behaviors during parsing. See ParseOptions for more information. The default value is
      #   +ParseOptions::DEFAULT_HTML+.
      #
      # [Yields]
      #   If a block is given, a Nokogiri::XML::ParseOptions object is yielded to the block which
      #   can be configured before parsing. See ParseOptions for more information.
      #
      # [Returns] HTML4::DocumentFragment
      #
      # === Context \Node
      #
      # If a context node is specified using +context:+, then the fragment will be created by
      # calling XML::Node#parse on that node, so the parser will behave as if that Node is the
      # parent of the fragment subtree.
      #
      def initialize(
        document, input = nil,
        context_ = nil, options_ = XML::ParseOptions::DEFAULT_HTML,
        context: context_, options: options_
      ) # rubocop:disable Lint/MissingSuper
        return self unless input

        options = Nokogiri::XML::ParseOptions.new(options) if Integer === options
        @parse_options = options
        yield options if block_given?

        if context
          preexisting_errors = document.errors.dup
          node_set = context.parse("<div>#{input}</div>", options)
          node_set.first.children.each { |child| child.parent = self } unless node_set.empty?
          self.errors = document.errors - preexisting_errors
        else
          # This is a horrible hack, but I don't care
          path = if /^\s*?<body/i.match?(input)
            "/html/body"
          else
            "/html/body/node()"
          end

          temp_doc = HTML4::Document.parse("<html><body>#{input}", nil, document.encoding, options)
          temp_doc.xpath(path).each { |child| child.parent = self }
          self.errors = temp_doc.errors
        end
        children
      end
    end
  end
end
