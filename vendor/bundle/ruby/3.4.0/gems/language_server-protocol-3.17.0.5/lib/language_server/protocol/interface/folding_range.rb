module LanguageServer
  module Protocol
    module Interface
      #
      # Represents a folding range. To be valid, start and end line must be bigger
      # than zero and smaller than the number of lines in the document. Clients
      # are free to ignore invalid ranges.
      #
      class FoldingRange
        def initialize(start_line:, start_character: nil, end_line:, end_character: nil, kind: nil, collapsed_text: nil)
          @attributes = {}

          @attributes[:startLine] = start_line
          @attributes[:startCharacter] = start_character if start_character
          @attributes[:endLine] = end_line
          @attributes[:endCharacter] = end_character if end_character
          @attributes[:kind] = kind if kind
          @attributes[:collapsedText] = collapsed_text if collapsed_text

          @attributes.freeze
        end

        #
        # The zero-based start line of the range to fold. The folded area starts
        # after the line's last character. To be valid, the end must be zero or
        # larger and smaller than the number of lines in the document.
        #
        # @return [number]
        def start_line
          attributes.fetch(:startLine)
        end

        #
        # The zero-based character offset from where the folded range starts. If
        # not defined, defaults to the length of the start line.
        #
        # @return [number]
        def start_character
          attributes.fetch(:startCharacter)
        end

        #
        # The zero-based end line of the range to fold. The folded area ends with
        # the line's last character. To be valid, the end must be zero or larger
        # and smaller than the number of lines in the document.
        #
        # @return [number]
        def end_line
          attributes.fetch(:endLine)
        end

        #
        # The zero-based character offset before the folded range ends. If not
        # defined, defaults to the length of the end line.
        #
        # @return [number]
        def end_character
          attributes.fetch(:endCharacter)
        end

        #
        # Describes the kind of the folding range such as `comment` or `region`.
        # The kind is used to categorize folding ranges and used by commands like
        # 'Fold all comments'. See [FoldingRangeKind](#FoldingRangeKind) for an
        # enumeration of standardized kinds.
        #
        # @return [string]
        def kind
          attributes.fetch(:kind)
        end

        #
        # The text that the client should show when the specified range is
        # collapsed. If not defined or not supported by the client, a default
        # will be chosen by the client.
        #
        # @return [string]
        def collapsed_text
          attributes.fetch(:collapsedText)
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
