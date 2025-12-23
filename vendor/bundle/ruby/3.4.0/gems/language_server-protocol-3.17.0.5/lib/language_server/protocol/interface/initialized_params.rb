module LanguageServer
  module Protocol
    module Interface
      class InitializedParams
        def initialize()
          @attributes = {}


          @attributes.freeze
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
