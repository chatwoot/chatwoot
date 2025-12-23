module LanguageServer
  module Protocol
    module Interface
      class WorkspaceEdit
        def initialize(changes: nil, document_changes: nil, change_annotations: nil)
          @attributes = {}

          @attributes[:changes] = changes if changes
          @attributes[:documentChanges] = document_changes if document_changes
          @attributes[:changeAnnotations] = change_annotations if change_annotations

          @attributes.freeze
        end

        #
        # Holds changes to existing resources.
        #
        # @return [{}]
        def changes
          attributes.fetch(:changes)
        end

        #
        # Depending on the client capability
        # `workspace.workspaceEdit.resourceOperations` document changes are either
        # an array of `TextDocumentEdit`s to express changes to n different text
        # documents where each text document edit addresses a specific version of
        # a text document. Or it can contain above `TextDocumentEdit`s mixed with
        # create, rename and delete file / folder operations.
        #
        # Whether a client supports versioned document edits is expressed via
        # `workspace.workspaceEdit.documentChanges` client capability.
        #
        # If a client neither supports `documentChanges` nor
        # `workspace.workspaceEdit.resourceOperations` then only plain `TextEdit`s
        # using the `changes` property are supported.
        #
        # @return [TextDocumentEdit[] | (TextDocumentEdit | CreateFile | RenameFile | DeleteFile)[]]
        def document_changes
          attributes.fetch(:documentChanges)
        end

        #
        # A map of change annotations that can be referenced in
        # `AnnotatedTextEdit`s or create, rename and delete file / folder
        # operations.
        #
        # Whether clients honor this property depends on the client capability
        # `workspace.changeAnnotationSupport`.
        #
        # @return [{ [id: string]: ChangeAnnotation; }]
        def change_annotations
          attributes.fetch(:changeAnnotations)
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
