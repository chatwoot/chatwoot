# frozen_string_literal: true

module Rails
  module HTML
    # === Rails::HTML::PermitScrubber
    #
    # +Rails::HTML::PermitScrubber+ allows you to permit only your own tags and/or attributes.
    #
    # +Rails::HTML::PermitScrubber+ can be subclassed to determine:
    # - When a node should be skipped via +skip_node?+.
    # - When a node is allowed via +allowed_node?+.
    # - When an attribute should be scrubbed via +scrub_attribute?+.
    #
    # Subclasses don't need to worry if tags or attributes are set or not.
    # If tags or attributes are not set, Loofah's behavior will be used.
    # If you override +allowed_node?+ and no tags are set, it will not be called.
    # Instead Loofahs behavior will be used.
    # Likewise for +scrub_attribute?+ and attributes respectively.
    #
    # Text and CDATA nodes are skipped by default.
    # Unallowed elements will be stripped, i.e. element is removed but its subtree kept.
    # Supplied tags and attributes should be Enumerables.
    #
    # +tags=+
    # If set, elements excluded will be stripped.
    # If not, elements are stripped based on Loofahs +HTML5::Scrub.allowed_element?+.
    #
    # +attributes=+
    # If set, attributes excluded will be removed.
    # If not, attributes are removed based on Loofahs +HTML5::Scrub.scrub_attributes+.
    #
    #  class CommentScrubber < Rails::HTML::PermitScrubber
    #    def initialize
    #      super
    #      self.tags = %w(form script comment blockquote)
    #    end
    #
    #    def skip_node?(node)
    #      node.text?
    #    end
    #
    #    def scrub_attribute?(name)
    #      name == "style"
    #    end
    #  end
    #
    # See the documentation for +Nokogiri::XML::Node+ to understand what's possible
    # with nodes: https://nokogiri.org/rdoc/Nokogiri/XML/Node.html
    class PermitScrubber < Loofah::Scrubber
      attr_reader :tags, :attributes, :prune

      def initialize(prune: false)
        @prune = prune
        @direction = @prune ? :top_down : :bottom_up
        @tags, @attributes = nil, nil
      end

      def tags=(tags)
        @tags = validate!(tags, :tags)
      end

      def attributes=(attributes)
        @attributes = validate!(attributes, :attributes)
      end

      def scrub(node)
        if Loofah::HTML5::Scrub.cdata_needs_escaping?(node)
          replacement = Loofah::HTML5::Scrub.cdata_escape(node)
          node.replace(replacement)
          return CONTINUE
        end
        return CONTINUE if skip_node?(node)

        unless (node.element? || node.comment?) && keep_node?(node)
          return STOP unless scrub_node(node) == CONTINUE
        end

        scrub_attributes(node)
        CONTINUE
      end

      protected
        def allowed_node?(node)
          @tags.include?(node.name)
        end

        def skip_node?(node)
          node.text?
        end

        def scrub_attribute?(name)
          !@attributes.include?(name)
        end

        def keep_node?(node)
          if @tags
            allowed_node?(node)
          else
            Loofah::HTML5::Scrub.allowed_element?(node.name)
          end
        end

        def scrub_node(node)
          # If a node has a namespace, then it's a tag in either a `math` or `svg` foreign context,
          # and we should always prune it to avoid namespace confusion and mutation XSS vectors.
          unless prune || node.namespace
            node.before(node.children)
          end
          node.remove
        end

        def scrub_attributes(node)
          if @attributes
            node.attribute_nodes.each do |attr|
              if scrub_attribute?(attr.name)
                attr.remove
              else
                scrub_attribute(node, attr)
              end
            end

            scrub_css_attribute(node)
          else
            Loofah::HTML5::Scrub.scrub_attributes(node)
          end
        end

        def scrub_css_attribute(node)
          if Loofah::HTML5::Scrub.respond_to?(:scrub_css_attribute)
            Loofah::HTML5::Scrub.scrub_css_attribute(node)
          else
            style = node.attributes["style"]
            style.value = Loofah::HTML5::Scrub.scrub_css(style.value) if style
          end
        end

        def validate!(var, name)
          if var && !var.is_a?(Enumerable)
            raise ArgumentError, "You should pass :#{name} as an Enumerable"
          end

          if var && name == :tags
            if var.include?("mglyph")
              warn("WARNING: 'mglyph' tags cannot be allowed by the PermitScrubber and will be scrubbed")
              var.delete("mglyph")
            end

            if var.include?("malignmark")
              warn("WARNING: 'malignmark' tags cannot be allowed by the PermitScrubber and will be scrubbed")
              var.delete("malignmark")
            end

            if var.include?("noscript")
              warn("WARNING: 'noscript' tags cannot be allowed by the PermitScrubber and will be scrubbed")
              var.delete("noscript")
            end
          end

          var
        end

        def scrub_attribute(node, attr_node)
          attr_name = if attr_node.namespace
            "#{attr_node.namespace.prefix}:#{attr_node.node_name}"
          else
            attr_node.node_name
          end

          return if Loofah::HTML5::SafeList::ATTR_VAL_IS_URI.include?(attr_name) && Loofah::HTML5::Scrub.scrub_uri_attribute(attr_node)

          if Loofah::HTML5::SafeList::SVG_ATTR_VAL_ALLOWS_REF.include?(attr_name)
            Loofah::HTML5::Scrub.scrub_attribute_that_allows_local_ref(attr_node)
          end

          if Loofah::HTML5::SafeList::SVG_ALLOW_LOCAL_HREF.include?(node.name) && attr_name == "xlink:href" && attr_node.value =~ /^\s*[^#\s].*/m
            attr_node.remove
          end

          node.remove_attribute(attr_node.name) if attr_name == "src" && attr_node.value !~ /[^[:space:]]/

          Loofah::HTML5::Scrub.force_correct_attribute_escaping! node
        end
    end

    # === Rails::HTML::TargetScrubber
    #
    # Where +Rails::HTML::PermitScrubber+ picks out tags and attributes to permit in
    # sanitization, +Rails::HTML::TargetScrubber+ targets them for removal.
    #
    # +tags=+
    # If set, elements included will be stripped.
    #
    # +attributes=+
    # If set, attributes included will be removed.
    class TargetScrubber < PermitScrubber
      def allowed_node?(node)
        !super
      end

      def scrub_attribute?(name)
        !super
      end
    end

    # === Rails::HTML::TextOnlyScrubber
    #
    # +Rails::HTML::TextOnlyScrubber+ allows you to permit text nodes.
    #
    # Unallowed elements will be stripped, i.e. element is removed but its subtree kept.
    class TextOnlyScrubber < Loofah::Scrubber
      def initialize
        @direction = :bottom_up
      end

      def scrub(node)
        if node.text?
          CONTINUE
        else
          node.before node.children
          node.remove
        end
      end
    end
  end
end
