# coding: utf-8
# frozen_string_literal: true

module Nokogiri
  module XML
    # Options that control the parsing behavior for XML::Document, XML::DocumentFragment,
    # HTML4::Document, HTML4::DocumentFragment, XSLT::Stylesheet, and XML::Schema.
    #
    # These options directly expose libxml2's parse options, which are all boolean in the sense that
    # an option is "on" or "off".
    #
    # 💡 Note that HTML5 parsing has a separate, orthogonal set of options due to the nature of the
    # HTML5 specification. See Nokogiri::HTML5.
    #
    # ⚠ Not all parse options are supported on JRuby. Nokogiri will attempt to invoke the equivalent
    # behavior in Xerces/NekoHTML on JRuby when it's possible.
    #
    # == Setting and unsetting parse options
    #
    # You can build your own combinations of parse options by using any of the following methods:
    #
    # [ParseOptions method chaining]
    #
    #   Every option has an equivalent method in lowercase. You can chain these methods together to
    #   set various combinations.
    #
    #     # Set the HUGE & PEDANTIC options
    #     po = Nokogiri::XML::ParseOptions.new.huge.pedantic
    #     doc = Nokogiri::XML::Document.parse(xml, nil, nil, po)
    #
    #   Every option has an equivalent <code>no{option}</code> method in lowercase. You can call these
    #   methods on an instance of ParseOptions to unset the option.
    #
    #     # Set the HUGE & PEDANTIC options
    #     po = Nokogiri::XML::ParseOptions.new.huge.pedantic
    #
    #     # later we want to modify the options
    #     po.nohuge # Unset the HUGE option
    #     po.nopedantic # Unset the PEDANTIC option
    #
    #   💡 Note that some options begin with "no" leading to the logical but perhaps unintuitive
    #   double negative:
    #
    #     po.nocdata # Set the NOCDATA parse option
    #     po.nonocdata # Unset the NOCDATA parse option
    #
    #   💡 Note that negation is not available for STRICT, which is itself a negation of all other
    #   features.
    #
    #
    # [Using Ruby Blocks]
    #
    #   Most parsing methods will accept a block for configuration of parse options, and we
    #   recommend chaining the setter methods:
    #
    #     doc = Nokogiri::XML::Document.parse(xml) { |config| config.huge.pedantic }
    #
    #
    # [ParseOptions constants]
    #
    #   You can also use the constants declared under Nokogiri::XML::ParseOptions to set various
    #   combinations. They are bits in a bitmask, and so can be combined with bitwise operators:
    #
    #     po = Nokogiri::XML::ParseOptions.new(Nokogiri::XML::ParseOptions::HUGE | Nokogiri::XML::ParseOptions::PEDANTIC)
    #     doc = Nokogiri::XML::Document.parse(xml, nil, nil, po)
    #
    class ParseOptions
      # Strict parsing
      STRICT      = 0

      # Recover from errors. On by default for XML::Document, XML::DocumentFragment,
      # HTML4::Document, HTML4::DocumentFragment, XSLT::Stylesheet, and XML::Schema.
      RECOVER     = 1 << 0

      # Substitute entities. Off by default.
      #
      # ⚠ This option enables entity substitution, contrary to what the name implies.
      #
      # ⚠ <b>It is UNSAFE to set this option</b> when parsing untrusted documents.
      NOENT       = 1 << 1

      # Load external subsets. On by default for XSLT::Stylesheet.
      #
      # ⚠ <b>It is UNSAFE to set this option</b> when parsing untrusted documents.
      DTDLOAD     = 1 << 2

      # Default DTD attributes. On by default for XSLT::Stylesheet.
      DTDATTR     = 1 << 3

      # Validate with the DTD. Off by default.
      DTDVALID    = 1 << 4

      # Suppress error reports. On by default for HTML4::Document and HTML4::DocumentFragment
      NOERROR     = 1 << 5

      # Suppress warning reports. On by default for HTML4::Document and HTML4::DocumentFragment
      NOWARNING   = 1 << 6

      # Enable pedantic error reporting. Off by default.
      PEDANTIC    = 1 << 7

      # Remove blank nodes. Off by default.
      NOBLANKS    = 1 << 8

      # Use the SAX1 interface internally. Off by default.
      SAX1        = 1 << 9

      # Implement XInclude substitution. Off by default.
      XINCLUDE    = 1 << 10

      # Forbid network access. On by default for XML::Document, XML::DocumentFragment,
      # HTML4::Document, HTML4::DocumentFragment, XSLT::Stylesheet, and XML::Schema.
      #
      # ⚠ <b>It is UNSAFE to unset this option</b> when parsing untrusted documents.
      NONET       = 1 << 11

      # Do not reuse the context dictionary. Off by default.
      NODICT      = 1 << 12

      # Remove redundant namespaces declarations. Off by default.
      NSCLEAN     = 1 << 13

      # Merge CDATA as text nodes. On by default for XSLT::Stylesheet.
      NOCDATA     = 1 << 14

      # Do not generate XInclude START/END nodes. Off by default.
      NOXINCNODE  = 1 << 15

      # Compact small text nodes. Off by default.
      #
      # ⚠ No modification of the DOM tree is allowed after parsing. libxml2 may crash if you try to
      # modify the tree.
      COMPACT     = 1 << 16

      # Parse using XML-1.0 before update 5. Off by default
      OLD10       = 1 << 17

      # Do not fixup XInclude xml:base uris. Off by default
      NOBASEFIX   = 1 << 18

      # Relax any hardcoded limit from the parser. Off by default.
      #
      # ⚠ <b>It is UNSAFE to set this option</b> when parsing untrusted documents.
      HUGE        = 1 << 19

      # Support line numbers up to <code>long int</code> (default is a <code>short int</code>). On
      # by default for for XML::Document, XML::DocumentFragment, HTML4::Document,
      # HTML4::DocumentFragment, XSLT::Stylesheet, and XML::Schema.
      BIG_LINES   = 1 << 22

      # The options mask used by default for parsing XML::Document and XML::DocumentFragment
      DEFAULT_XML  = RECOVER | NONET | BIG_LINES

      # The options mask used by default used for parsing XSLT::Stylesheet
      DEFAULT_XSLT = RECOVER | NONET | NOENT | DTDLOAD | DTDATTR | NOCDATA | BIG_LINES

      # The options mask used by default used for parsing HTML4::Document and HTML4::DocumentFragment
      DEFAULT_HTML = RECOVER | NOERROR | NOWARNING | NONET | BIG_LINES

      # The options mask used by default used for parsing XML::Schema
      DEFAULT_SCHEMA = NONET | BIG_LINES

      attr_accessor :options

      def initialize(options = STRICT)
        @options = options
      end

      constants.each do |constant|
        next if constant.to_sym == :STRICT

        class_eval <<~RUBY, __FILE__, __LINE__ + 1
          def #{constant.downcase}
            @options |= #{constant}
            self
          end

          def no#{constant.downcase}
            @options &= ~#{constant}
            self
          end

          def #{constant.downcase}?
            #{constant} & @options == #{constant}
          end
        RUBY
      end

      def strict
        @options &= ~RECOVER
        self
      end

      def strict?
        @options & RECOVER == STRICT
      end

      def ==(other)
        other.to_i == to_i
      end

      alias_method :to_i, :options

      def inspect
        options = []
        self.class.constants.each do |k|
          options << k.downcase if send(:"#{k.downcase}?")
        end
        super.sub(/>$/, " " + options.join(", ") + ">")
      end
    end
  end
end
