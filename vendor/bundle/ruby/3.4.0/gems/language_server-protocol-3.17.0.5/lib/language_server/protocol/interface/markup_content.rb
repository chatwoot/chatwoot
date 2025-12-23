module LanguageServer
  module Protocol
    module Interface
      #
      # A `MarkupContent` literal represents a string value which content is
      # interpreted base on its kind flag. Currently the protocol supports
      # `plaintext` and `markdown` as markup kinds.
      #
      # If the kind is `markdown` then the value can contain fenced code blocks like
      # in GitHub issues.
      #
      # Here is an example how such a string can be constructed using
      # JavaScript / TypeScript:
      # ```typescript
      # let markdown: MarkdownContent = {
      # kind: MarkupKind.Markdown,
      # value: [
      # '# Header',
      # 'Some text',
      # '```typescript',
      # 'someCode();',
      # '```'
      # ].join('\n')
      # };
      # ```
      #
      # *Please Note* that clients might sanitize the return markdown. A client could
      # decide to remove HTML from the markdown to avoid script execution.
      #
      class MarkupContent
        def initialize(kind:, value:)
          @attributes = {}

          @attributes[:kind] = kind
          @attributes[:value] = value

          @attributes.freeze
        end

        #
        # The type of the Markup
        #
        # @return [MarkupKind]
        def kind
          attributes.fetch(:kind)
        end

        #
        # The content itself
        #
        # @return [string]
        def value
          attributes.fetch(:value)
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
