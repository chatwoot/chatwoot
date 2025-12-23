module LanguageServer
  module Protocol
    module Interface
      class RenameParams
        def initialize(text_document:, position:, work_done_token: nil, new_name:)
          @attributes = {}

          @attributes[:textDocument] = text_document
          @attributes[:position] = position
          @attributes[:workDoneToken] = work_done_token if work_done_token
          @attributes[:newName] = new_name

          @attributes.freeze
        end

        #
        # The text document.
        #
        # @return [TextDocumentIdentifier]
        def text_document
          attributes.fetch(:textDocument)
        end

        #
        # The position inside the text document.
        #
        # @return [Position]
        def position
          attributes.fetch(:position)
        end

        #
        # An optional token that a server can use to report work done progress.
        #
        # @return [ProgressToken]
        def work_done_token
          attributes.fetch(:workDoneToken)
        end

        #
        # The new name of the symbol. If the given name is not valid the
        # request must return a [ResponseError](#ResponseError) with an
        # appropriate message set.
        #
        # @return [string]
        def new_name
          attributes.fetch(:newName)
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
