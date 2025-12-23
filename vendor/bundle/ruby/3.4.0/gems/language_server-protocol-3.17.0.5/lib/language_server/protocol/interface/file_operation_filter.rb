module LanguageServer
  module Protocol
    module Interface
      #
      # A filter to describe in which file operation requests or notifications
      # the server is interested in.
      #
      class FileOperationFilter
        def initialize(scheme: nil, pattern:)
          @attributes = {}

          @attributes[:scheme] = scheme if scheme
          @attributes[:pattern] = pattern

          @attributes.freeze
        end

        #
        # A Uri like `file` or `untitled`.
        #
        # @return [string]
        def scheme
          attributes.fetch(:scheme)
        end

        #
        # The actual file operation pattern.
        #
        # @return [FileOperationPattern]
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
