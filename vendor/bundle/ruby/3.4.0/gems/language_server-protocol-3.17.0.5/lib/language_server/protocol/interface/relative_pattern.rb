module LanguageServer
  module Protocol
    module Interface
      #
      # A relative pattern is a helper to construct glob patterns that are matched
      # relatively to a base URI. The common value for a `baseUri` is a workspace
      # folder root, but it can be another absolute URI as well.
      #
      class RelativePattern
        def initialize(base_uri:, pattern:)
          @attributes = {}

          @attributes[:baseUri] = base_uri
          @attributes[:pattern] = pattern

          @attributes.freeze
        end

        #
        # A workspace folder or a base URI to which this pattern will be matched
        # against relatively.
        #
        # @return [string | WorkspaceFolder]
        def base_uri
          attributes.fetch(:baseUri)
        end

        #
        # The actual glob pattern;
        #
        # @return [string]
        def pattern
          attributes.fetch(:pattern)
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
