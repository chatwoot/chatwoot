module LanguageServer
  module Protocol
    module Interface
      class WorkspaceEditClientCapabilities
        def initialize(document_changes: nil, resource_operations: nil, failure_handling: nil, normalizes_line_endings: nil, change_annotation_support: nil)
          @attributes = {}

          @attributes[:documentChanges] = document_changes if document_changes
          @attributes[:resourceOperations] = resource_operations if resource_operations
          @attributes[:failureHandling] = failure_handling if failure_handling
          @attributes[:normalizesLineEndings] = normalizes_line_endings if normalizes_line_endings
          @attributes[:changeAnnotationSupport] = change_annotation_support if change_annotation_support

          @attributes.freeze
        end

        #
        # The client supports versioned document changes in `WorkspaceEdit`s
        #
        # @return [boolean]
        def document_changes
          attributes.fetch(:documentChanges)
        end

        #
        # The resource operations the client supports. Clients should at least
        # support 'create', 'rename' and 'delete' files and folders.
        #
        # @return [ResourceOperationKind[]]
        def resource_operations
          attributes.fetch(:resourceOperations)
        end

        #
        # The failure handling strategy of a client if applying the workspace edit
        # fails.
        #
        # @return [FailureHandlingKind]
        def failure_handling
          attributes.fetch(:failureHandling)
        end

        #
        # Whether the client normalizes line endings to the client specific
        # setting.
        # If set to `true` the client will normalize line ending characters
        # in a workspace edit to the client specific new line character(s).
        #
        # @return [boolean]
        def normalizes_line_endings
          attributes.fetch(:normalizesLineEndings)
        end

        #
        # Whether the client in general supports change annotations on text edits,
        # create file, rename file and delete file changes.
        #
        # @return [{ groupsOnLabel?: boolean; }]
        def change_annotation_support
          attributes.fetch(:changeAnnotationSupport)
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
