module LanguageServer
  module Protocol
    module Interface
      #
      # An inlay hint label part allows for interactive and composite labels
      # of inlay hints.
      #
      class InlayHintLabelPart
        def initialize(value:, tooltip: nil, location: nil, command: nil)
          @attributes = {}

          @attributes[:value] = value
          @attributes[:tooltip] = tooltip if tooltip
          @attributes[:location] = location if location
          @attributes[:command] = command if command

          @attributes.freeze
        end

        #
        # The value of this label part.
        #
        # @return [string]
        def value
          attributes.fetch(:value)
        end

        #
        # The tooltip text when you hover over this label part. Depending on
        # the client capability `inlayHint.resolveSupport` clients might resolve
        # this property late using the resolve request.
        #
        # @return [string | MarkupContent]
        def tooltip
          attributes.fetch(:tooltip)
        end

        #
        # An optional source code location that represents this
        # label part.
        #
        # The editor will use this location for the hover and for code navigation
        # features: This part will become a clickable link that resolves to the
        # definition of the symbol at the given location (not necessarily the
        # location itself), it shows the hover that shows at the given location,
        # and it shows a context menu with further code navigation commands.
        #
        # Depending on the client capability `inlayHint.resolveSupport` clients
        # might resolve this property late using the resolve request.
        #
        # @return [Location]
        def location
          attributes.fetch(:location)
        end

        #
        # An optional command for this label part.
        #
        # Depending on the client capability `inlayHint.resolveSupport` clients
        # might resolve this property late using the resolve request.
        #
        # @return [Command]
        def command
          attributes.fetch(:command)
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
