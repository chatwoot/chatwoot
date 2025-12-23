module LanguageServer
  module Protocol
    module Interface
      class RegistrationParams
        def initialize(registrations:)
          @attributes = {}

          @attributes[:registrations] = registrations

          @attributes.freeze
        end

        # @return [Registration[]]
        def registrations
          attributes.fetch(:registrations)
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
