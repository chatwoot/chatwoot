module LanguageServer
  module Protocol
    module Interface
      #
      # Client capabilities specific to regular expressions.
      #
      class RegularExpressionsClientCapabilities
        def initialize(engine:, version: nil)
          @attributes = {}

          @attributes[:engine] = engine
          @attributes[:version] = version if version

          @attributes.freeze
        end

        #
        # The engine's name.
        #
        # @return [string]
        def engine
          attributes.fetch(:engine)
        end

        #
        # The engine's version.
        #
        # @return [string]
        def version
          attributes.fetch(:version)
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
