module LanguageServer
  module Protocol
    module Interface
      class ServerCapabilities
        def initialize(position_encoding: nil, text_document_sync: nil, notebook_document_sync: nil, completion_provider: nil, hover_provider: nil, signature_help_provider: nil, declaration_provider: nil, definition_provider: nil, type_definition_provider: nil, implementation_provider: nil, references_provider: nil, document_highlight_provider: nil, document_symbol_provider: nil, code_action_provider: nil, code_lens_provider: nil, document_link_provider: nil, color_provider: nil, document_formatting_provider: nil, document_range_formatting_provider: nil, document_on_type_formatting_provider: nil, rename_provider: nil, folding_range_provider: nil, execute_command_provider: nil, selection_range_provider: nil, linked_editing_range_provider: nil, call_hierarchy_provider: nil, semantic_tokens_provider: nil, moniker_provider: nil, type_hierarchy_provider: nil, inline_value_provider: nil, inlay_hint_provider: nil, diagnostic_provider: nil, workspace_symbol_provider: nil, workspace: nil, experimental: nil)
          @attributes = {}

          @attributes[:positionEncoding] = position_encoding if position_encoding
          @attributes[:textDocumentSync] = text_document_sync if text_document_sync
          @attributes[:notebookDocumentSync] = notebook_document_sync if notebook_document_sync
          @attributes[:completionProvider] = completion_provider if completion_provider
          @attributes[:hoverProvider] = hover_provider if hover_provider
          @attributes[:signatureHelpProvider] = signature_help_provider if signature_help_provider
          @attributes[:declarationProvider] = declaration_provider if declaration_provider
          @attributes[:definitionProvider] = definition_provider if definition_provider
          @attributes[:typeDefinitionProvider] = type_definition_provider if type_definition_provider
          @attributes[:implementationProvider] = implementation_provider if implementation_provider
          @attributes[:referencesProvider] = references_provider if references_provider
          @attributes[:documentHighlightProvider] = document_highlight_provider if document_highlight_provider
          @attributes[:documentSymbolProvider] = document_symbol_provider if document_symbol_provider
          @attributes[:codeActionProvider] = code_action_provider if code_action_provider
          @attributes[:codeLensProvider] = code_lens_provider if code_lens_provider
          @attributes[:documentLinkProvider] = document_link_provider if document_link_provider
          @attributes[:colorProvider] = color_provider if color_provider
          @attributes[:documentFormattingProvider] = document_formatting_provider if document_formatting_provider
          @attributes[:documentRangeFormattingProvider] = document_range_formatting_provider if document_range_formatting_provider
          @attributes[:documentOnTypeFormattingProvider] = document_on_type_formatting_provider if document_on_type_formatting_provider
          @attributes[:renameProvider] = rename_provider if rename_provider
          @attributes[:foldingRangeProvider] = folding_range_provider if folding_range_provider
          @attributes[:executeCommandProvider] = execute_command_provider if execute_command_provider
          @attributes[:selectionRangeProvider] = selection_range_provider if selection_range_provider
          @attributes[:linkedEditingRangeProvider] = linked_editing_range_provider if linked_editing_range_provider
          @attributes[:callHierarchyProvider] = call_hierarchy_provider if call_hierarchy_provider
          @attributes[:semanticTokensProvider] = semantic_tokens_provider if semantic_tokens_provider
          @attributes[:monikerProvider] = moniker_provider if moniker_provider
          @attributes[:typeHierarchyProvider] = type_hierarchy_provider if type_hierarchy_provider
          @attributes[:inlineValueProvider] = inline_value_provider if inline_value_provider
          @attributes[:inlayHintProvider] = inlay_hint_provider if inlay_hint_provider
          @attributes[:diagnosticProvider] = diagnostic_provider if diagnostic_provider
          @attributes[:workspaceSymbolProvider] = workspace_symbol_provider if workspace_symbol_provider
          @attributes[:workspace] = workspace if workspace
          @attributes[:experimental] = experimental if experimental

          @attributes.freeze
        end

        #
        # The position encoding the server picked from the encodings offered
        # by the client via the client capability `general.positionEncodings`.
        #
        # If the client didn't provide any position encodings the only valid
        # value that a server can return is 'utf-16'.
        #
        # If omitted it defaults to 'utf-16'.
        #
        # @return [string]
        def position_encoding
          attributes.fetch(:positionEncoding)
        end

        #
        # Defines how text documents are synced. Is either a detailed structure
        # defining each notification or for backwards compatibility the
        # TextDocumentSyncKind number. If omitted it defaults to
        # `TextDocumentSyncKind.None`.
        #
        # @return [TextDocumentSyncOptions | TextDocumentSyncKind]
        def text_document_sync
          attributes.fetch(:textDocumentSync)
        end

        #
        # Defines how notebook documents are synced.
        #
        # @return [NotebookDocumentSyncOptions | NotebookDocumentSyncRegistrationOptions]
        def notebook_document_sync
          attributes.fetch(:notebookDocumentSync)
        end

        #
        # The server provides completion support.
        #
        # @return [CompletionOptions]
        def completion_provider
          attributes.fetch(:completionProvider)
        end

        #
        # The server provides hover support.
        #
        # @return [boolean | HoverOptions]
        def hover_provider
          attributes.fetch(:hoverProvider)
        end

        #
        # The server provides signature help support.
        #
        # @return [SignatureHelpOptions]
        def signature_help_provider
          attributes.fetch(:signatureHelpProvider)
        end

        #
        # The server provides go to declaration support.
        #
        # @return [boolean | DeclarationOptions | DeclarationRegistrationOptions]
        def declaration_provider
          attributes.fetch(:declarationProvider)
        end

        #
        # The server provides goto definition support.
        #
        # @return [boolean | DefinitionOptions]
        def definition_provider
          attributes.fetch(:definitionProvider)
        end

        #
        # The server provides goto type definition support.
        #
        # @return [boolean | TypeDefinitionOptions | TypeDefinitionRegistrationOptions]
        def type_definition_provider
          attributes.fetch(:typeDefinitionProvider)
        end

        #
        # The server provides goto implementation support.
        #
        # @return [boolean | ImplementationOptions | ImplementationRegistrationOptions]
        def implementation_provider
          attributes.fetch(:implementationProvider)
        end

        #
        # The server provides find references support.
        #
        # @return [boolean | ReferenceOptions]
        def references_provider
          attributes.fetch(:referencesProvider)
        end

        #
        # The server provides document highlight support.
        #
        # @return [boolean | DocumentHighlightOptions]
        def document_highlight_provider
          attributes.fetch(:documentHighlightProvider)
        end

        #
        # The server provides document symbol support.
        #
        # @return [boolean | DocumentSymbolOptions]
        def document_symbol_provider
          attributes.fetch(:documentSymbolProvider)
        end

        #
        # The server provides code actions. The `CodeActionOptions` return type is
        # only valid if the client signals code action literal support via the
        # property `textDocument.codeAction.codeActionLiteralSupport`.
        #
        # @return [boolean | CodeActionOptions]
        def code_action_provider
          attributes.fetch(:codeActionProvider)
        end

        #
        # The server provides code lens.
        #
        # @return [CodeLensOptions]
        def code_lens_provider
          attributes.fetch(:codeLensProvider)
        end

        #
        # The server provides document link support.
        #
        # @return [DocumentLinkOptions]
        def document_link_provider
          attributes.fetch(:documentLinkProvider)
        end

        #
        # The server provides color provider support.
        #
        # @return [boolean | DocumentColorOptions | DocumentColorRegistrationOptions]
        def color_provider
          attributes.fetch(:colorProvider)
        end

        #
        # The server provides document formatting.
        #
        # @return [boolean | DocumentFormattingOptions]
        def document_formatting_provider
          attributes.fetch(:documentFormattingProvider)
        end

        #
        # The server provides document range formatting.
        #
        # @return [boolean | DocumentRangeFormattingOptions]
        def document_range_formatting_provider
          attributes.fetch(:documentRangeFormattingProvider)
        end

        #
        # The server provides document formatting on typing.
        #
        # @return [DocumentOnTypeFormattingOptions]
        def document_on_type_formatting_provider
          attributes.fetch(:documentOnTypeFormattingProvider)
        end

        #
        # The server provides rename support. RenameOptions may only be
        # specified if the client states that it supports
        # `prepareSupport` in its initial `initialize` request.
        #
        # @return [boolean | RenameOptions]
        def rename_provider
          attributes.fetch(:renameProvider)
        end

        #
        # The server provides folding provider support.
        #
        # @return [boolean | FoldingRangeOptions | FoldingRangeRegistrationOptions]
        def folding_range_provider
          attributes.fetch(:foldingRangeProvider)
        end

        #
        # The server provides execute command support.
        #
        # @return [ExecuteCommandOptions]
        def execute_command_provider
          attributes.fetch(:executeCommandProvider)
        end

        #
        # The server provides selection range support.
        #
        # @return [boolean | SelectionRangeOptions | SelectionRangeRegistrationOptions]
        def selection_range_provider
          attributes.fetch(:selectionRangeProvider)
        end

        #
        # The server provides linked editing range support.
        #
        # @return [boolean | LinkedEditingRangeOptions | LinkedEditingRangeRegistrationOptions]
        def linked_editing_range_provider
          attributes.fetch(:linkedEditingRangeProvider)
        end

        #
        # The server provides call hierarchy support.
        #
        # @return [boolean | CallHierarchyOptions | CallHierarchyRegistrationOptions]
        def call_hierarchy_provider
          attributes.fetch(:callHierarchyProvider)
        end

        #
        # The server provides semantic tokens support.
        #
        # @return [SemanticTokensOptions | SemanticTokensRegistrationOptions]
        def semantic_tokens_provider
          attributes.fetch(:semanticTokensProvider)
        end

        #
        # Whether server provides moniker support.
        #
        # @return [boolean | MonikerOptions | MonikerRegistrationOptions]
        def moniker_provider
          attributes.fetch(:monikerProvider)
        end

        #
        # The server provides type hierarchy support.
        #
        # @return [boolean | TypeHierarchyOptions | TypeHierarchyRegistrationOptions]
        def type_hierarchy_provider
          attributes.fetch(:typeHierarchyProvider)
        end

        #
        # The server provides inline values.
        #
        # @return [boolean | InlineValueOptions | InlineValueRegistrationOptions]
        def inline_value_provider
          attributes.fetch(:inlineValueProvider)
        end

        #
        # The server provides inlay hints.
        #
        # @return [boolean | InlayHintOptions | InlayHintRegistrationOptions]
        def inlay_hint_provider
          attributes.fetch(:inlayHintProvider)
        end

        #
        # The server has support for pull model diagnostics.
        #
        # @return [DiagnosticOptions | DiagnosticRegistrationOptions]
        def diagnostic_provider
          attributes.fetch(:diagnosticProvider)
        end

        #
        # The server provides workspace symbol support.
        #
        # @return [boolean | WorkspaceSymbolOptions]
        def workspace_symbol_provider
          attributes.fetch(:workspaceSymbolProvider)
        end

        #
        # Workspace specific server capabilities
        #
        # @return [{ workspaceFolders?: WorkspaceFoldersServerCapabilities; fileOperations?: { didCreate?: FileOperationRegistrationOptions; ... 4 more ...; willDelete?: FileOperationRegistrationOptions; }; }]
        def workspace
          attributes.fetch(:workspace)
        end

        #
        # Experimental server capabilities.
        #
        # @return [LSPAny]
        def experimental
          attributes.fetch(:experimental)
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
