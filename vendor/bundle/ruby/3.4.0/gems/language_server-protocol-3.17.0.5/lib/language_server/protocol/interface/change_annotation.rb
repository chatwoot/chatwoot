module LanguageServer
  module Protocol
    module Interface
      #
      # Additional information that describes document changes.
      #
      class ChangeAnnotation
        def initialize(label:, needs_confirmation: nil, description: nil)
          @attributes = {}

          @attributes[:label] = label
          @attributes[:needsConfirmation] = needs_confirmation if needs_confirmation
          @attributes[:description] = description if description

          @attributes.freeze
        end

        #
        # A human-readable string describing the actual change. The string
        # is rendered prominent in the user interface.
        #
        # @return [string]
        def label
          attributes.fetch(:label)
        end

        #
        # A flag which indicates that user confirmation is needed
        # before applying the change.
        #
        # @return [boolean]
        def needs_confirmation
          attributes.fetch(:needsConfirmation)
        end

        #
        # A human-readable string which is rendered less prominent in
        # the user interface.
        #
        # @return [string]
        def description
          attributes.fetch(:description)
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
