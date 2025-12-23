module LanguageServer
  module Protocol
    module Interface
      class TextDocumentSyncClientCapabilities
        def initialize(dynamic_registration: nil, will_save: nil, will_save_wait_until: nil, did_save: nil)
          @attributes = {}

          @attributes[:dynamicRegistration] = dynamic_registration if dynamic_registration
          @attributes[:willSave] = will_save if will_save
          @attributes[:willSaveWaitUntil] = will_save_wait_until if will_save_wait_until
          @attributes[:didSave] = did_save if did_save

          @attributes.freeze
        end

        #
        # Whether text document synchronization supports dynamic registration.
        #
        # @return [boolean]
        def dynamic_registration
          attributes.fetch(:dynamicRegistration)
        end

        #
        # The client supports sending will save notifications.
        #
        # @return [boolean]
        def will_save
          attributes.fetch(:willSave)
        end

        #
        # The client supports sending a will save request and
        # waits for a response providing text edits which will
        # be applied to the document before it is saved.
        #
        # @return [boolean]
        def will_save_wait_until
          attributes.fetch(:willSaveWaitUntil)
        end

        #
        # The client supports did save notifications.
        #
        # @return [boolean]
        def did_save
          attributes.fetch(:didSave)
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
