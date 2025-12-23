module LanguageServer
  module Protocol
    module Interface
      #
      # A document link is a range in a text document that links to an internal or
      # external resource, like another text document or a web site.
      #
      class DocumentLink
        def initialize(range:, target: nil, tooltip: nil, data: nil)
          @attributes = {}

          @attributes[:range] = range
          @attributes[:target] = target if target
          @attributes[:tooltip] = tooltip if tooltip
          @attributes[:data] = data if data

          @attributes.freeze
        end

        #
        # The range this link applies to.
        #
        # @return [Range]
        def range
          attributes.fetch(:range)
        end

        #
        # The uri this link points to. If missing a resolve request is sent later.
        #
        # @return [string]
        def target
          attributes.fetch(:target)
        end

        #
        # The tooltip text when you hover over this link.
        #
        # If a tooltip is provided, is will be displayed in a string that includes
        # instructions on how to trigger the link, such as `{0} (ctrl + click)`.
        # The specific instructions vary depending on OS, user settings, and
        # localization.
        #
        # @return [string]
        def tooltip
          attributes.fetch(:tooltip)
        end

        #
        # A data entry field that is preserved on a document link between a
        # DocumentLinkRequest and a DocumentLinkResolveRequest.
        #
        # @return [LSPAny]
        def data
          attributes.fetch(:data)
        end

        attr_reader :attributes

        def to_hash
          attributes
        end

        def to_json(*args)
          to_hash.to_json(*args)
        end
      end
    end
  end
end
