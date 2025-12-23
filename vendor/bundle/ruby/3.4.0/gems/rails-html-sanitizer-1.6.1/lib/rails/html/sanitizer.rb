# frozen_string_literal: true

module Rails
  module HTML
    class Sanitizer
      class << self
        def html5_support?
          return @html5_support if defined?(@html5_support)

          @html5_support = Loofah.respond_to?(:html5_support?) && Loofah.html5_support?
        end

        def best_supported_vendor
          html5_support? ? Rails::HTML5::Sanitizer : Rails::HTML4::Sanitizer
        end
      end

      def sanitize(html, options = {})
        raise NotImplementedError, "subclasses must implement sanitize method."
      end

      private
        def remove_xpaths(node, xpaths)
          node.xpath(*xpaths).remove
          node
        end

        def properly_encode(fragment, options)
          fragment.xml? ? fragment.to_xml(options) : fragment.to_html(options)
        end
    end

    module Concern
      module ComposedSanitize
        def sanitize(html, options = {})
          return unless html
          return html if html.empty?

          serialize(scrub(parse_fragment(html), options))
        end
      end

      module Parser
        module HTML4
          def parse_fragment(html)
            Loofah.html4_fragment(html)
          end
        end

        module HTML5
          def parse_fragment(html)
            Loofah.html5_fragment(html)
          end
        end if Rails::HTML::Sanitizer.html5_support?
      end

      module Scrubber
        module Full
          def scrub(fragment, options = {})
            fragment.scrub!(TextOnlyScrubber.new)
          end
        end

        module Link
          def initialize
            super
            @link_scrubber = TargetScrubber.new
            @link_scrubber.tags = %w(a)
            @link_scrubber.attributes = %w(href)
          end

          def scrub(fragment, options = {})
            fragment.scrub!(@link_scrubber)
          end
        end

        module SafeList
          # The default safe list for tags
          DEFAULT_ALLOWED_TAGS = Set.new([
                                           "a",
                                           "abbr",
                                           "acronym",
                                           "address",
                                           "b",
                                           "big",
                                           "blockquote",
                                           "br",
                                           "cite",
                                           "code",
                                           "dd",
                                           "del",
                                           "dfn",
                                           "div",
                                           "dl",
                                           "dt",
                                           "em",
                                           "h1",
                                           "h2",
                                           "h3",
                                           "h4",
                                           "h5",
                                           "h6",
                                           "hr",
                                           "i",
                                           "img",
                                           "ins",
                                           "kbd",
                                           "li",
                                           "mark",
                                           "ol",
                                           "p",
                                           "pre",
                                           "samp",
                                           "small",
                                           "span",
                                           "strong",
                                           "sub",
                                           "sup",
                                           "time",
                                           "tt",
                                           "ul",
                                           "var",
                                         ]).freeze

          # The default safe list for attributes
          DEFAULT_ALLOWED_ATTRIBUTES = Set.new([
                                                 "abbr",
                                                 "alt",
                                                 "cite",
                                                 "class",
                                                 "datetime",
                                                 "height",
                                                 "href",
                                                 "lang",
                                                 "name",
                                                 "src",
                                                 "title",
                                                 "width",
                                                 "xml:lang",
                                               ]).freeze

          def self.included(klass)
            class << klass
              attr_accessor :allowed_tags
              attr_accessor :allowed_attributes
            end

            klass.allowed_tags = DEFAULT_ALLOWED_TAGS.dup
            klass.allowed_attributes = DEFAULT_ALLOWED_ATTRIBUTES.dup
          end

          def initialize(prune: false)
            @permit_scrubber = PermitScrubber.new(prune: prune)
          end

          def scrub(fragment, options = {})
            if scrubber = options[:scrubber]
              # No duck typing, Loofah ensures subclass of Loofah::Scrubber
              fragment.scrub!(scrubber)
            elsif allowed_tags(options) || allowed_attributes(options)
              @permit_scrubber.tags = allowed_tags(options)
              @permit_scrubber.attributes = allowed_attributes(options)
              fragment.scrub!(@permit_scrubber)
            else
              fragment.scrub!(:strip)
            end
          end

          def sanitize_css(style_string)
            Loofah::HTML5::Scrub.scrub_css(style_string)
          end

          private
            def allowed_tags(options)
              options[:tags] || self.class.allowed_tags
            end

            def allowed_attributes(options)
              options[:attributes] || self.class.allowed_attributes
            end
        end
      end

      module Serializer
        module UTF8Encode
          def serialize(fragment)
            properly_encode(fragment, encoding: "UTF-8")
          end
        end
      end
    end
  end

  module HTML4
    module Sanitizer
      module VendorMethods
        def full_sanitizer
          Rails::HTML4::FullSanitizer
        end

        def link_sanitizer
          Rails::HTML4::LinkSanitizer
        end

        def safe_list_sanitizer
          Rails::HTML4::SafeListSanitizer
        end

        def white_list_sanitizer # :nodoc:
          safe_list_sanitizer
        end
      end

      extend VendorMethods
    end

    # == Rails::HTML4::FullSanitizer
    #
    # Removes all tags from HTML4 but strips out scripts, forms and comments.
    #
    #   full_sanitizer = Rails::HTML4::FullSanitizer.new
    #   full_sanitizer.sanitize("<b>Bold</b> no more!  <a href='more.html'>See more here</a>...")
    #   # => "Bold no more!  See more here..."
    #
    class FullSanitizer < Rails::HTML::Sanitizer
      include HTML::Concern::ComposedSanitize
      include HTML::Concern::Parser::HTML4
      include HTML::Concern::Scrubber::Full
      include HTML::Concern::Serializer::UTF8Encode
    end

    # == Rails::HTML4::LinkSanitizer
    #
    # Removes +a+ tags and +href+ attributes from HTML4 leaving only the link text.
    #
    #   link_sanitizer = Rails::HTML4::LinkSanitizer.new
    #   link_sanitizer.sanitize('<a href="example.com">Only the link text will be kept.</a>')
    #   # => "Only the link text will be kept."
    #
    class LinkSanitizer < Rails::HTML::Sanitizer
      include HTML::Concern::ComposedSanitize
      include HTML::Concern::Parser::HTML4
      include HTML::Concern::Scrubber::Link
      include HTML::Concern::Serializer::UTF8Encode
    end

    # == Rails::HTML4::SafeListSanitizer
    #
    # Sanitizes HTML4 and CSS from an extensive safe list.
    #
    # === Whitespace
    #
    # We can't make any guarantees about whitespace being kept or stripped.  Loofah uses Nokogiri,
    # which wraps either a C or Java parser for the respective Ruby implementation.  Those two
    # parsers determine how whitespace is ultimately handled.
    #
    # When the stripped markup will be rendered the users browser won't take whitespace into account
    # anyway. It might be better to suggest your users wrap their whitespace sensitive content in
    # pre tags or that you do so automatically.
    #
    # === Options
    #
    # Sanitizes both html and css via the safe lists found in
    # Rails::HTML::Concern::Scrubber::SafeList
    #
    # SafeListSanitizer also accepts options to configure the safe list used when sanitizing html.
    # There's a class level option:
    #
    #   Rails::HTML4::SafeListSanitizer.allowed_tags = %w(table tr td)
    #   Rails::HTML4::SafeListSanitizer.allowed_attributes = %w(id class style)
    #
    # Tags and attributes can also be passed to +sanitize+.  Passed options take precedence over the
    # class level options.
    #
    # === Examples
    #
    #   safe_list_sanitizer = Rails::HTML4::SafeListSanitizer.new
    #
    #   # default: sanitize via a extensive safe list of allowed elements
    #   safe_list_sanitizer.sanitize(@article.body)
    #
    #   # sanitize via the supplied tags and attributes
    #   safe_list_sanitizer.sanitize(
    #     @article.body,
    #     tags: %w(table tr td),
    #     attributes: %w(id class style),
    #   )
    #
    #   # sanitize via a custom Loofah scrubber
    #   safe_list_sanitizer.sanitize(@article.body, scrubber: ArticleScrubber.new)
    #
    #   # prune nodes from the tree instead of stripping tags and leaving inner content
    #   safe_list_sanitizer = Rails::HTML4::SafeListSanitizer.new(prune: true)
    #
    #   # the sanitizer can also sanitize CSS
    #   safe_list_sanitizer.sanitize_css('background-color: #000;')
    #
    class SafeListSanitizer < Rails::HTML::Sanitizer
      include HTML::Concern::ComposedSanitize
      include HTML::Concern::Parser::HTML4
      include HTML::Concern::Scrubber::SafeList
      include HTML::Concern::Serializer::UTF8Encode
    end
  end

  module HTML5
    class Sanitizer
      class << self
        def full_sanitizer
          Rails::HTML5::FullSanitizer
        end

        def link_sanitizer
          Rails::HTML5::LinkSanitizer
        end

        def safe_list_sanitizer
          Rails::HTML5::SafeListSanitizer
        end

        def white_list_sanitizer # :nodoc:
          safe_list_sanitizer
        end
      end
    end

    # == Rails::HTML5::FullSanitizer
    #
    # Removes all tags from HTML5 but strips out scripts, forms and comments.
    #
    #   full_sanitizer = Rails::HTML5::FullSanitizer.new
    #   full_sanitizer.sanitize("<b>Bold</b> no more!  <a href='more.html'>See more here</a>...")
    #   # => "Bold no more!  See more here..."
    #
    class FullSanitizer < Rails::HTML::Sanitizer
      include HTML::Concern::ComposedSanitize
      include HTML::Concern::Parser::HTML5
      include HTML::Concern::Scrubber::Full
      include HTML::Concern::Serializer::UTF8Encode
    end

    # == Rails::HTML5::LinkSanitizer
    #
    # Removes +a+ tags and +href+ attributes from HTML5 leaving only the link text.
    #
    #   link_sanitizer = Rails::HTML5::LinkSanitizer.new
    #   link_sanitizer.sanitize('<a href="example.com">Only the link text will be kept.</a>')
    #   # => "Only the link text will be kept."
    #
    class LinkSanitizer < Rails::HTML::Sanitizer
      include HTML::Concern::ComposedSanitize
      include HTML::Concern::Parser::HTML5
      include HTML::Concern::Scrubber::Link
      include HTML::Concern::Serializer::UTF8Encode
    end

    # == Rails::HTML5::SafeListSanitizer
    #
    # Sanitizes HTML5 and CSS from an extensive safe list.
    #
    # === Whitespace
    #
    # We can't make any guarantees about whitespace being kept or stripped.  Loofah uses Nokogiri,
    # which wraps either a C or Java parser for the respective Ruby implementation.  Those two
    # parsers determine how whitespace is ultimately handled.
    #
    # When the stripped markup will be rendered the users browser won't take whitespace into account
    # anyway. It might be better to suggest your users wrap their whitespace sensitive content in
    # pre tags or that you do so automatically.
    #
    # === Options
    #
    # Sanitizes both html and css via the safe lists found in
    # Rails::HTML::Concern::Scrubber::SafeList
    #
    # SafeListSanitizer also accepts options to configure the safe list used when sanitizing html.
    # There's a class level option:
    #
    #   Rails::HTML5::SafeListSanitizer.allowed_tags = %w(table tr td)
    #   Rails::HTML5::SafeListSanitizer.allowed_attributes = %w(id class style)
    #
    # Tags and attributes can also be passed to +sanitize+.  Passed options take precedence over the
    # class level options.
    #
    # === Examples
    #
    #   safe_list_sanitizer = Rails::HTML5::SafeListSanitizer.new
    #
    #   # default: sanitize via a extensive safe list of allowed elements
    #   safe_list_sanitizer.sanitize(@article.body)
    #
    #   # sanitize via the supplied tags and attributes
    #   safe_list_sanitizer.sanitize(
    #     @article.body,
    #     tags: %w(table tr td),
    #     attributes: %w(id class style),
    #   )
    #
    #   # sanitize via a custom Loofah scrubber
    #   safe_list_sanitizer.sanitize(@article.body, scrubber: ArticleScrubber.new)
    #
    #   # prune nodes from the tree instead of stripping tags and leaving inner content
    #   safe_list_sanitizer = Rails::HTML5::SafeListSanitizer.new(prune: true)
    #
    #   # the sanitizer can also sanitize CSS
    #   safe_list_sanitizer.sanitize_css('background-color: #000;')
    #
    class SafeListSanitizer < Rails::HTML::Sanitizer
      include HTML::Concern::ComposedSanitize
      include HTML::Concern::Parser::HTML5
      include HTML::Concern::Scrubber::SafeList
      include HTML::Concern::Serializer::UTF8Encode
    end
  end if Rails::HTML::Sanitizer.html5_support?

  module HTML
    Sanitizer.extend(HTML4::Sanitizer::VendorMethods) # :nodoc:
    FullSanitizer = HTML4::FullSanitizer # :nodoc:
    LinkSanitizer = HTML4::LinkSanitizer # :nodoc:
    SafeListSanitizer = HTML4::SafeListSanitizer # :nodoc:
    WhiteListSanitizer = SafeListSanitizer # :nodoc:
  end
end
