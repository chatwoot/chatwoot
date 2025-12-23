module LanguageServer
  module Protocol
    module Interface
      class CompletionItem
        def initialize(label:, label_details: nil, kind: nil, tags: nil, detail: nil, documentation: nil, deprecated: nil, preselect: nil, sort_text: nil, filter_text: nil, insert_text: nil, insert_text_format: nil, insert_text_mode: nil, text_edit: nil, text_edit_text: nil, additional_text_edits: nil, commit_characters: nil, command: nil, data: nil)
          @attributes = {}

          @attributes[:label] = label
          @attributes[:labelDetails] = label_details if label_details
          @attributes[:kind] = kind if kind
          @attributes[:tags] = tags if tags
          @attributes[:detail] = detail if detail
          @attributes[:documentation] = documentation if documentation
          @attributes[:deprecated] = deprecated if deprecated
          @attributes[:preselect] = preselect if preselect
          @attributes[:sortText] = sort_text if sort_text
          @attributes[:filterText] = filter_text if filter_text
          @attributes[:insertText] = insert_text if insert_text
          @attributes[:insertTextFormat] = insert_text_format if insert_text_format
          @attributes[:insertTextMode] = insert_text_mode if insert_text_mode
          @attributes[:textEdit] = text_edit if text_edit
          @attributes[:textEditText] = text_edit_text if text_edit_text
          @attributes[:additionalTextEdits] = additional_text_edits if additional_text_edits
          @attributes[:commitCharacters] = commit_characters if commit_characters
          @attributes[:command] = command if command
          @attributes[:data] = data if data

          @attributes.freeze
        end

        #
        # The label of this completion item.
        #
        # The label property is also by default the text that
        # is inserted when selecting this completion.
        #
        # If label details are provided the label itself should
        # be an unqualified name of the completion item.
        #
        # @return [string]
        def label
          attributes.fetch(:label)
        end

        #
        # Additional details for the label
        #
        # @return [CompletionItemLabelDetails]
        def label_details
          attributes.fetch(:labelDetails)
        end

        #
        # The kind of this completion item. Based of the kind
        # an icon is chosen by the editor. The standardized set
        # of available values is defined in `CompletionItemKind`.
        #
        # @return [CompletionItemKind]
        def kind
          attributes.fetch(:kind)
        end

        #
        # Tags for this completion item.
        #
        # @return [1[]]
        def tags
          attributes.fetch(:tags)
        end

        #
        # A human-readable string with additional information
        # about this item, like type or symbol information.
        #
        # @return [string]
        def detail
          attributes.fetch(:detail)
        end

        #
        # A human-readable string that represents a doc-comment.
        #
        # @return [string | MarkupContent]
        def documentation
          attributes.fetch(:documentation)
        end

        #
        # Indicates if this item is deprecated.
        #
        # @return [boolean]
        def deprecated
          attributes.fetch(:deprecated)
        end

        #
        # Select this item when showing.
        #
        # *Note* that only one completion item can be selected and that the
        # tool / client decides which item that is. The rule is that the *first*
        # item of those that match best is selected.
        #
        # @return [boolean]
        def preselect
          attributes.fetch(:preselect)
        end

        #
        # A string that should be used when comparing this item
        # with other items. When omitted the label is used
        # as the sort text for this item.
        #
        # @return [string]
        def sort_text
          attributes.fetch(:sortText)
        end

        #
        # A string that should be used when filtering a set of
        # completion items. When omitted the label is used as the
        # filter text for this item.
        #
        # @return [string]
        def filter_text
          attributes.fetch(:filterText)
        end

        #
        # A string that should be inserted into a document when selecting
        # this completion. When omitted the label is used as the insert text
        # for this item.
        #
        # The `insertText` is subject to interpretation by the client side.
        # Some tools might not take the string literally. For example
        # VS Code when code complete is requested in this example
        # `con<cursor position>` and a completion item with an `insertText` of
        # `console` is provided it will only insert `sole`. Therefore it is
        # recommended to use `textEdit` instead since it avoids additional client
        # side interpretation.
        #
        # @return [string]
        def insert_text
          attributes.fetch(:insertText)
        end

        #
        # The format of the insert text. The format applies to both the
        # `insertText` property and the `newText` property of a provided
        # `textEdit`. If omitted defaults to `InsertTextFormat.PlainText`.
        #
        # Please note that the insertTextFormat doesn't apply to
        # `additionalTextEdits`.
        #
        # @return [InsertTextFormat]
        def insert_text_format
          attributes.fetch(:insertTextFormat)
        end

        #
        # How whitespace and indentation is handled during completion
        # item insertion. If not provided the client's default value depends on
        # the `textDocument.completion.insertTextMode` client capability.
        #
        # @return [InsertTextMode]
        def insert_text_mode
          attributes.fetch(:insertTextMode)
        end

        #
        # An edit which is applied to a document when selecting this completion.
        # When an edit is provided the value of `insertText` is ignored.
        #
        # *Note:* The range of the edit must be a single line range and it must
        # contain the position at which completion has been requested.
        #
        # Most editors support two different operations when accepting a completion
        # item. One is to insert a completion text and the other is to replace an
        # existing text with a completion text. Since this can usually not be
        # predetermined by a server it can report both ranges. Clients need to
        # signal support for `InsertReplaceEdit`s via the
        # `textDocument.completion.completionItem.insertReplaceSupport` client
        # capability property.
        #
        # *Note 1:* The text edit's range as well as both ranges from an insert
        # replace edit must be a [single line] and they must contain the position
        # at which completion has been requested.
        # *Note 2:* If an `InsertReplaceEdit` is returned the edit's insert range
        # must be a prefix of the edit's replace range, that means it must be
        # contained and starting at the same position.
        #
        # @return [TextEdit | InsertReplaceEdit]
        def text_edit
          attributes.fetch(:textEdit)
        end

        #
        # The edit text used if the completion item is part of a CompletionList and
        # CompletionList defines an item default for the text edit range.
        #
        # Clients will only honor this property if they opt into completion list
        # item defaults using the capability `completionList.itemDefaults`.
        #
        # If not provided and a list's default range is provided the label
        # property is used as a text.
        #
        # @return [string]
        def text_edit_text
          attributes.fetch(:textEditText)
        end

        #
        # An optional array of additional text edits that are applied when
        # selecting this completion. Edits must not overlap (including the same
        # insert position) with the main edit nor with themselves.
        #
        # Additional text edits should be used to change text unrelated to the
        # current cursor position (for example adding an import statement at the
        # top of the file if the completion item will insert an unqualified type).
        #
        # @return [TextEdit[]]
        def additional_text_edits
          attributes.fetch(:additionalTextEdits)
        end

        #
        # An optional set of characters that when pressed while this completion is
        # active will accept it first and then type that character. *Note* that all
        # commit characters should have `length=1` and that superfluous characters
        # will be ignored.
        #
        # @return [string[]]
        def commit_characters
          attributes.fetch(:commitCharacters)
        end

        #
        # An optional command that is executed *after* inserting this completion.
        # *Note* that additional modifications to the current document should be
        # described with the additionalTextEdits-property.
        #
        # @return [Command]
        def command
          attributes.fetch(:command)
        end

        #
        # A data entry field that is preserved on a completion item between
        # a completion and a completion resolve request.
        #
        # @return [LSPAny]
        def data
          attributes.fetch(:data)
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
