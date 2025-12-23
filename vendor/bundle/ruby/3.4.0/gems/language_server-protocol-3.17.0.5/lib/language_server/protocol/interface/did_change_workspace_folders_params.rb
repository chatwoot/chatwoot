module LanguageServer
  module Protocol
    module Interface
      class DidChangeWorkspaceFoldersParams
        def initialize(event:)
          @attributes = {}

          @attributes[:event] = event

          @attributes.freeze
        end

        #
        # The actual workspace folder change event.
        #
        # @return [WorkspaceFoldersChangeEvent]
        def event
          attributes.fetch(:event)
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
