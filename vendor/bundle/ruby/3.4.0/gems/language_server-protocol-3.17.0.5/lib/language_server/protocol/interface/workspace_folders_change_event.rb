module LanguageServer
  module Protocol
    module Interface
      #
      # The workspace folder change event.
      #
      class WorkspaceFoldersChangeEvent
        def initialize(added:, removed:)
          @attributes = {}

          @attributes[:added] = added
          @attributes[:removed] = removed

          @attributes.freeze
        end

        #
        # The array of added workspace folders
        #
        # @return [WorkspaceFolder[]]
        def added
          attributes.fetch(:added)
        end

        #
        # The array of the removed workspace folders
        #
        # @return [WorkspaceFolder[]]
        def removed
          attributes.fetch(:removed)
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
