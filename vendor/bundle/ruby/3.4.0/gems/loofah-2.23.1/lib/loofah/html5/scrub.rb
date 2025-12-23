# frozen_string_literal: true

require "cgi"
require "crass"

module Loofah
  module HTML5 # :nodoc:
    module Scrub
      CONTROL_CHARACTERS = /[`\u0000-\u0020\u007f\u0080-\u0101]/
      CSS_KEYWORDISH = /\A(#[0-9a-fA-F]+|rgb\(\d+%?,\d*%?,?\d*%?\)?|-?\d{0,3}\.?\d{0,10}(ch|cm|r?em|ex|in|lh|mm|pc|pt|px|Q|vmax|vmin|vw|vh|%|,|\))?)\z/ # rubocop:disable Layout/LineLength
      CRASS_SEMICOLON = { node: :semicolon, raw: ";" }
      CSS_IMPORTANT = "!important"
      CSS_WHITESPACE = " "
      CSS_PROPERTY_STRING_WITHOUT_EMBEDDED_QUOTES = /\A(["'])?[^"']+\1\z/
      DATA_ATTRIBUTE_NAME = /\Adata-[\w-]+\z/

      class << self
        def allowed_element?(element_name)
          ::Loofah::HTML5::SafeList::ALLOWED_ELEMENTS_WITH_LIBXML2.include?(element_name)
        end

        #  alternative implementation of the html5lib attribute scrubbing algorithm
        def scrub_attributes(node)
          node.attribute_nodes.each do |attr_node|
            attr_name = if attr_node.namespace
              "#{attr_node.namespace.prefix}:#{attr_node.node_name}"
            else
              attr_node.node_name
            end

            if DATA_ATTRIBUTE_NAME.match?(attr_name)
              next
            end

            unless SafeList::ALLOWED_ATTRIBUTES.include?(attr_name)
              attr_node.remove
              next
            end

            if SafeList::ATTR_VAL_IS_URI.include?(attr_name)
              next if scrub_uri_attribute(attr_node)
            end

            if SafeList::SVG_ATTR_VAL_ALLOWS_REF.include?(attr_name)
              scrub_attribute_that_allows_local_ref(attr_node)
            end

            next unless SafeList::SVG_ALLOW_LOCAL_HREF.include?(node.name) &&
              attr_name == "xlink:href" &&
              attr_node.value =~ /^\s*[^#\s].*/m

            attr_node.remove
            next
          end

          scrub_css_attribute(node)

          node.attribute_nodes.each do |attr_node|
            if attr_node.value !~ /[^[:space:]]/ && attr_node.name !~ DATA_ATTRIBUTE_NAME
              node.remove_attribute(attr_node.name)
            end
          end

          force_correct_attribute_escaping!(node)
        end

        def scrub_css_attribute(node)
          style = node.attributes["style"]
          style.value = scrub_css(style.value) if style
        end

        def scrub_css(style)
          url_flags = [:url, :bad_url]
          style_tree = Crass.parse_properties(style)
          sanitized_tree = []

          style_tree.each do |node|
            next unless node[:node] == :property
            next if node[:children].any? do |child|
              url_flags.include?(child[:node])
            end

            name = node[:name].downcase
            next unless SafeList::ALLOWED_CSS_PROPERTIES.include?(name) ||
              SafeList::ALLOWED_SVG_PROPERTIES.include?(name) ||
              SafeList::SHORTHAND_CSS_PROPERTIES.include?(name.split("-").first)

            value = node[:children].map do |child|
              case child[:node]
              when :whitespace
                CSS_WHITESPACE
              when :string
                if CSS_PROPERTY_STRING_WITHOUT_EMBEDDED_QUOTES.match?(child[:raw])
                  Crass::Parser.stringify(child)
                end
              when :function
                if SafeList::ALLOWED_CSS_FUNCTIONS.include?(child[:name].downcase)
                  Crass::Parser.stringify(child)
                end
              when :ident
                keyword = child[:value]
                if !SafeList::SHORTHAND_CSS_PROPERTIES.include?(name.split("-").first) ||
                    SafeList::ALLOWED_CSS_KEYWORDS.include?(keyword) ||
                    (keyword =~ CSS_KEYWORDISH)
                  keyword
                end
              else
                child[:raw]
              end
            end.compact.join.strip

            next if value.empty?

            value << CSS_WHITESPACE << CSS_IMPORTANT if node[:important]
            propstring = format("%s:%s", name, value)
            sanitized_node = Crass.parse_properties(propstring).first
            sanitized_tree << sanitized_node << CRASS_SEMICOLON
          end

          Crass::Parser.stringify(sanitized_tree)
        end

        def scrub_attribute_that_allows_local_ref(attr_node)
          return unless attr_node.value

          nodes = Crass::Parser.new(attr_node.value).parse_component_values

          values = nodes.map do |node|
            case node[:node]
            when :url
              if node[:value].start_with?("#")
                node[:raw]
              end
            when :hash, :ident, :string
              node[:raw]
            end
          end.compact

          attr_node.value = values.join(" ")
        end

        def scrub_uri_attribute(attr_node)
          # this block lifted nearly verbatim from HTML5 sanitization
          val_unescaped = CGI.unescapeHTML(attr_node.value).gsub(CONTROL_CHARACTERS, "").downcase
          if val_unescaped =~ /^[a-z0-9][-+.a-z0-9]*:/ &&
              !SafeList::ALLOWED_PROTOCOLS.include?(val_unescaped.split(SafeList::PROTOCOL_SEPARATOR)[0])
            attr_node.remove
            return true
          elsif val_unescaped.split(SafeList::PROTOCOL_SEPARATOR)[0] == "data"
            # permit only allowed data mediatypes
            mediatype = val_unescaped.split(SafeList::PROTOCOL_SEPARATOR)[1]
            mediatype, _ = mediatype.split(";")[0..1] if mediatype
            if mediatype && !SafeList::ALLOWED_URI_DATA_MEDIATYPES.include?(mediatype)
              attr_node.remove
              return true
            end
          end
          false
        end

        #
        #  libxml2 >= 2.9.2 fails to escape comments within some attributes.
        #
        #  see comments about CVE-2018-8048 within the tests for more information
        #
        def force_correct_attribute_escaping!(node)
          return unless Nokogiri::VersionInfo.instance.libxml2?

          node.attribute_nodes.each do |attr_node|
            next unless LibxmlWorkarounds::BROKEN_ESCAPING_ATTRIBUTES.include?(attr_node.name)

            tag_name = LibxmlWorkarounds::BROKEN_ESCAPING_ATTRIBUTES_QUALIFYING_TAG[attr_node.name]
            next unless tag_name.nil? || tag_name == node.name

            #
            #  this block is just like CGI.escape in Ruby 2.4, but
            #  only encodes space and double-quote, to mimic
            #  pre-2.9.2 behavior
            #
            encoding = attr_node.value.encoding
            attr_node.value = attr_node.value.gsub(/[ "]/) do |m|
              "%" + m.unpack("H2" * m.bytesize).join("%").upcase
            end.force_encoding(encoding)
          end
        end

        def cdata_needs_escaping?(node)
          # Nokogiri's HTML4 parser on JRuby doesn't flag the child of a `style` tag as cdata, but it acts that way
          node.cdata? || (Nokogiri.jruby? && node.text? && node.parent.name == "style")
        end

        def cdata_escape(node)
          escaped_text = escape_tags(node.text)
          if Nokogiri.jruby?
            node.document.create_text_node(escaped_text)
          else
            node.document.create_cdata(escaped_text)
          end
        end

        TABLE_FOR_ESCAPE_HTML__ = {
          "<" => "&lt;",
          ">" => "&gt;",
          "&" => "&amp;",
        }

        def escape_tags(string)
          # modified version of CGI.escapeHTML from ruby 3.1
          enc = string.encoding
          if enc.ascii_compatible?
            string = string.b
            string.gsub!(/[<>&]/, TABLE_FOR_ESCAPE_HTML__)
            string.force_encoding(enc)
          else
            if enc.dummy?
              origenc = enc
              enc = Encoding::Converter.asciicompat_encoding(enc)
              string = enc ? string.encode(enc) : string.b
            end
            table = Hash[TABLE_FOR_ESCAPE_HTML__.map { |pair| pair.map { |s| s.encode(enc) } }]
            string = string.gsub(/#{"[<>&]".encode(enc)}/, table)
            string.encode!(origenc) if origenc
            string
          end
        end
      end
    end
  end
end
