module LanguageServer
  module Protocol
    module Interface
      #
      # A pattern to describe in which file operation requests or notifications
      # the server is interested in.
      #
      class FileOperationPattern
        def initialize(glob:, matches: nil, options: nil)
          @attributes = {}

          @attributes[:glob] = glob
          @attributes[:matches] = matches if matches
          @attributes[:options] = options if options

          @attributes.freeze
        end

        #
        # The glob pattern to match. Glob patterns can have the following syntax:
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
        def glob
          attributes.fetch(:glob)
        end

        #
        # Whether to match files or folders with this pattern.
        #
        # Matches both if undefined.
        #
        # @return [FileOperationPatternKind]
        def matches
          attributes.fetch(:matches)
        end

        #
        # Additional options used during matching.
        #
        # @return [FileOperationPatternOptions]
        def options
          attributes.fetch(:options)
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
