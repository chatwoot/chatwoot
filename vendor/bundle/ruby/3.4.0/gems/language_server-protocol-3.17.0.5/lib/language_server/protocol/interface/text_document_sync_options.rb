module LanguageServer
  module Protocol
    module Interface
      class TextDocumentSyncOptions
        def initialize(open_close: nil, change: nil, will_save: nil, will_save_wait_until: nil, save: nil)
          @attributes = {}

          @attributes[:openClose] = open_close if open_close
          @attributes[:change] = change if change
          @attributes[:willSave] = will_save if will_save
          @attributes[:willSaveWaitUntil] = will_save_wait_until if will_save_wait_until
          @attributes[:save] = save if save

          @attributes.freeze
        end

        #
        # Open and close notifications are sent to the server. If omitted open
        # close notifications should not be sent.
        # Open and close notifications are sent to the server. If omitted open
        # close notification should not be sent.
        #
        # @return [boolean]
        def open_close
          attributes.fetch(:openClose)
        end

        #
        # Change notifications are sent to the server. See
        # TextDocumentSyncKind.None, TextDocumentSyncKind.Full and
        # TextDocumentSyncKind.Incremental. If omitted it defaults to
        # TextDocumentSyncKind.None.
        #
        # @return [TextDocumentSyncKind]
        def change
          attributes.fetch(:change)
        end

        #
        # If present will save notifications are sent to the server. If omitted
        # the notification should not be sent.
        #
        # @return [boolean]
        def will_save
          attributes.fetch(:willSave)
        end

        #
        # If present will save wait until requests are sent to the server. If
        # omitted the request should not be sent.
        #
        # @return [boolean]
        def will_save_wait_until
          attributes.fetch(:willSaveWaitUntil)
        end

        #
        # If present save notifications are sent to the server. If omitted the
        # notification should not be sent.
        #
        # @return [boolean | SaveOptions]
        def save
          attributes.fetch(:save)
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
