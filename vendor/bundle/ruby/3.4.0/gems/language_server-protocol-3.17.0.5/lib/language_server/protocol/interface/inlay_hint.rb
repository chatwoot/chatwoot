module LanguageServer
  module Protocol
    module Interface
      #
      # Inlay hint information.
      #
      class InlayHint
        def initialize(position:, label:, kind: nil, text_edits: nil, tooltip: nil, padding_left: nil, padding_right: nil, data: nil)
          @attributes = {}

          @attributes[:position] = position
          @attributes[:label] = label
          @attributes[:kind] = kind if kind
          @attributes[:textEdits] = text_edits if text_edits
          @attributes[:tooltip] = tooltip if tooltip
          @attributes[:paddingLeft] = padding_left if padding_left
          @attributes[:paddingRight] = padding_right if padding_right
          @attributes[:data] = data if data

          @attributes.freeze
        end

        #
        # The position of this hint.
        #
        # @return [Position]
        def position
          attributes.fetch(:position)
        end

        #
        # The label of this hint. A human readable string or an array of
        # InlayHintLabelPart label parts.
        #
        # *Note* that neither the string nor the label part can be empty.
        #
        # @return [string | InlayHintLabelPart[]]
        def label
          attributes.fetch(:label)
        end

        #
        # The kind of this hint. Can be omitted in which case the client
        # should fall back to a reasonable default.
        #
        # @return [InlayHintKind]
        def kind
          attributes.fetch(:kind)
        end

        #
        # Optional text edits that are performed when accepting this inlay hint.
        #
        # *Note* that edits are expected to change the document so that the inlay
        # hint (or its nearest variant) is now part of the document and the inlay
        # hint itself is now obsolete.
        #
        # Depending on the client capability `inlayHint.resolveSupport` clients
        # might resolve this property late using the resolve request.
        #
        # @return [TextEdit[]]
        def text_edits
          attributes.fetch(:textEdits)
        end

        #
        # The tooltip text when you hover over this item.
        #
        # Depending on the client capability `inlayHint.resolveSupport` clients
        # might resolve this property late using the resolve request.
        #
        # @return [string | MarkupContent]
        def tooltip
          attributes.fetch(:tooltip)
        end

        #
        # Render padding before the hint.
        #
        # Note: Padding should use the editor's background color, not the
        # background color of the hint itself. That means padding can be used
        # to visually align/separate an inlay hint.
        #
        # @return [boolean]
        def padding_left
          attributes.fetch(:paddingLeft)
        end

        #
        # Render padding after the hint.
        #
        # Note: Padding should use the editor's background color, not the
        # background color of the hint itself. That means padding can be used
        # to visually align/separate an inlay hint.
        #
        # @return [boolean]
        def padding_right
          attributes.fetch(:paddingRight)
        end

        #
        # A data entry field that is preserved on an inlay hint between
        # a `textDocument/inlayHint` and a `inlayHint/resolve` request.
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
