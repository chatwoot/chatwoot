module LanguageServer
  module Protocol
    module Interface
      class InitializeError
        def initialize(retry:)
          @attributes = {}

          @attributes[:retry] = binding.local_variable_get(:retry)

          @attributes.freeze
        end

        #
        # Indicates whether the client execute the following retry logic:
        # (1) show the message provided by the ResponseError to the user
        # (2) user selects retry or cancel
        # (3) if user selected retry the initialize method is sent again.
        #
        # @return [boolean]
        def retry
          attributes.fetch(:retry)
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
