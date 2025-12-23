module LanguageServer
  module Protocol
    module Interface
      class DocumentFilter
        def initialize(language: nil, scheme: nil, pattern: nil)
          @attributes = {}

          @attributes[:language] = language if language
          @attributes[:scheme] = scheme if scheme
          @attributes[:pattern] = pattern if pattern

          @attributes.freeze
        end

        #
        # A language id, like `typescript`.
        #
        # @return [string]
        def language
          attributes.fetch(:language)
        end

        #
        # A Uri [scheme](#Uri.scheme), like `file` or `untitled`.
        #
        # @return [string]
        def scheme
          attributes.fetch(:scheme)
        end

        #
        # A glob pattern, like `*.{ts,js}`.
        #
        # Glob patterns can have the following syntax:
        # - `*` to match one or more characters in a path segment
        # - `?` to match on one character in a path segment
        # - `**` to match any number of path segments, including none
        # - `{}` to group sub patterns into an OR expression. (e.g. `**​/*.{ts,js}`
        # matches all TypeScript and JavaScript files)
        # - `[]` to declare a range of characters to match in a path segment
        # (e.g., `example.[0-9]` to match on `example.0`, `example.1`, …)
        # - `[!...]` to negate a range of characters to match in a path segment
        # (e.g., `example.[!0-9]` to match on `example.a`, `example.b`, but
        # not `example.0`)
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
