module LanguageServer
  module Protocol
    module Interface
      class DocumentOnTypeFormattingParams
        def initialize(text_document:, position:, ch:, options:)
          @attributes = {}

          @attributes[:textDocument] = text_document
          @attributes[:position] = position
          @attributes[:ch] = ch
          @attributes[:options] = options

          @attributes.freeze
        end

        #
        # The document to format.
        #
        # @return [TextDocumentIdentifier]
        def text_document
          attributes.fetch(:textDocument)
        end

        #
        # The position around which the on type formatting should happen.
        # This is not necessarily the exact position where the character denoted
        # by the property `ch` got typed.
        #
        # @return [Position]
        def position
          attributes.fetch(:position)
        end

        #
        # The character that has been typed that triggered the formatting
        # on type request. That is not necessarily the last character that
        # got inserted into the document since the client could auto insert
        # characters as well (e.g. like automatic brace completion).
        #
        # @return [string]
        def ch
          attributes.fetch(:ch)
        end

        #
        # The formatting options.
        #
        # @return [FormattingOptions]
        def options
          attributes.fetch(:options)
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
