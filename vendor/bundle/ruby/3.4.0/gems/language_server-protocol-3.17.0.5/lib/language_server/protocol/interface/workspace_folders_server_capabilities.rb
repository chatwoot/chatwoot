module LanguageServer
  module Protocol
    module Interface
      class WorkspaceFoldersServerCapabilities
        def initialize(supported: nil, change_notifications: nil)
          @attributes = {}

          @attributes[:supported] = supported if supported
          @attributes[:changeNotifications] = change_notifications if change_notifications

          @attributes.freeze
        end

        #
        # The server has support for workspace folders
        #
        # @return [boolean]
        def supported
          attributes.fetch(:supported)
        end

        #
        # Whether the server wants to receive workspace folder
        # change notifications.
        #
        # If a string is provided, the string is treated as an ID
        # under which the notification is registered on the client
        # side. The ID can be used to unregister for these events
        # using the `client/unregisterCapability` request.
        #
        # @return [string | boolean]
        def change_notifications
          attributes.fetch(:changeNotifications)
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
