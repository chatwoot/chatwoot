module LanguageServer
  module Protocol
    module Interface
      class SaveOptions
        def initialize(include_text: nil)
          @attributes = {}

          @attributes[:includeText] = include_text if include_text

          @attributes.freeze
        end

        #
        # The client is supposed to include the content on save.
        #
        # @return [boolean]
        def include_text
          attributes.fetch(:includeText)
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
