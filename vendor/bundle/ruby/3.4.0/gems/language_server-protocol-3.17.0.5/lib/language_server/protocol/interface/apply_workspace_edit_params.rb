module LanguageServer
  module Protocol
    module Interface
      class ApplyWorkspaceEditParams
        def initialize(label: nil, edit:)
          @attributes = {}

          @attributes[:label] = label if label
          @attributes[:edit] = edit

          @attributes.freeze
        end

        #
        # An optional label of the workspace edit. This label is
        # presented in the user interface for example on an undo
        # stack to undo the workspace edit.
        #
        # @return [string]
        def label
          attributes.fetch(:label)
        end

        #
        # The edits to apply.
        #
        # @return [WorkspaceEdit]
        def edit
          attributes.fetch(:edit)
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
