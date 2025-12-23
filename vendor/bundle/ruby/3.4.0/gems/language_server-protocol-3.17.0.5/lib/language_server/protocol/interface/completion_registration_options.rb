module LanguageServer
  module Protocol
    module Interface
      class CompletionRegistrationOptions
        def initialize(document_selector:, work_done_progress: nil, trigger_characters: nil, all_commit_characters: nil, resolve_provider: nil, completion_item: nil)
          @attributes = {}

          @attributes[:documentSelector] = document_selector
          @attributes[:workDoneProgress] = work_done_progress if work_done_progress
          @attributes[:triggerCharacters] = trigger_characters if trigger_characters
          @attributes[:allCommitCharacters] = all_commit_characters if all_commit_characters
          @attributes[:resolveProvider] = resolve_provider if resolve_provider
          @attributes[:completionItem] = completion_item if completion_item

          @attributes.freeze
        end

        #
        # A document selector to identify the scope of the registration. If set to
        # null the document selector provided on the client side will be used.
        #
        # @return [DocumentSelector]
        def document_selector
          attributes.fetch(:documentSelector)
        end

        # @return [boolean]
        def work_done_progress
          attributes.fetch(:workDoneProgress)
        end

        #
        # The additional characters, beyond the defaults provided by the client (typically
        # [a-zA-Z]), that should automatically trigger a completion request. For example
        # `.` in JavaScript represents the beginning of an object property or method and is
        # thus a good candidate for triggering a completion request.
        #
        # Most tools trigger a completion request automatically without explicitly
        # requesting it using a keyboard shortcut (e.g. Ctrl+Space). Typically they
        # do so when the user starts to type an identifier. For example if the user
        # types `c` in a JavaScript file code complete will automatically pop up
        # present `console` besides others as a completion item. Characters that
        # make up identifiers don't need to be listed here.
        #
        # @return [string[]]
        def trigger_characters
          attributes.fetch(:triggerCharacters)
        end

        #
        # The list of all possible characters that commit a completion. This field
        # can be used if clients don't support individual commit characters per
        # completion item. See client capability
        # `completion.completionItem.commitCharactersSupport`.
        #
        # If a server provides both `allCommitCharacters` and commit characters on
        # an individual completion item the ones on the completion item win.
        #
        # @return [string[]]
        def all_commit_characters
          attributes.fetch(:allCommitCharacters)
        end

        #
        # The server provides support to resolve additional
        # information for a completion item.
        #
        # @return [boolean]
        def resolve_provider
          attributes.fetch(:resolveProvider)
        end

        #
        # The server supports the following `CompletionItem` specific
        # capabilities.
        #
        # @return [{ labelDetailsSupport?: boolean; }]
        def completion_item
          attributes.fetch(:completionItem)
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
