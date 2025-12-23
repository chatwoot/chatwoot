module LanguageServer
  module Protocol
    module Interface
      #
      # Client workspace capabilities specific to inline values.
      #
      class InlineValueWorkspaceClientCapabilities
        def initialize(refresh_support: nil)
          @attributes = {}

          @attributes[:refreshSupport] = refresh_support if refresh_support

          @attributes.freeze
        end

        #
        # Whether the client implementation supports a refresh request sent from
        # the server to the client.
        #
        # Note that this event is global and will force the client to refresh all
        # inline values currently shown. It should be used with absolute care and
        # is useful for situation where a server for example detect a project wide
        # change that requires such a calculation.
        #
        # @return [boolean]
        def refresh_support
          attributes.fetch(:refreshSupport)
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
