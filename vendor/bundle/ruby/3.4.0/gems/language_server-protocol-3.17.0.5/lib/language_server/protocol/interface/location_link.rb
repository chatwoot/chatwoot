module LanguageServer
  module Protocol
    module Interface
      class LocationLink
        def initialize(origin_selection_range: nil, target_uri:, target_range:, target_selection_range:)
          @attributes = {}

          @attributes[:originSelectionRange] = origin_selection_range if origin_selection_range
          @attributes[:targetUri] = target_uri
          @attributes[:targetRange] = target_range
          @attributes[:targetSelectionRange] = target_selection_range

          @attributes.freeze
        end

        #
        # Span of the origin of this link.
        #
        # Used as the underlined span for mouse interaction. Defaults to the word
        # range at the mouse position.
        #
        # @return [Range]
        def origin_selection_range
          attributes.fetch(:originSelectionRange)
        end

        #
        # The target resource identifier of this link.
        #
        # @return [string]
        def target_uri
          attributes.fetch(:targetUri)
        end

        #
        # The full target range of this link. If the target for example is a symbol
        # then target range is the range enclosing this symbol not including
        # leading/trailing whitespace but everything else like comments. This
        # information is typically used to highlight the range in the editor.
        #
        # @return [Range]
        def target_range
          attributes.fetch(:targetRange)
        end

        #
        # The range that should be selected and revealed when this link is being
        # followed, e.g the name of a function. Must be contained by the
        # `targetRange`. See also `DocumentSymbol#range`
        #
        # @return [Range]
        def target_selection_range
          attributes.fetch(:targetSelectionRange)
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
