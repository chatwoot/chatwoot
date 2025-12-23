module LanguageServer
  module Protocol
    module Interface
      #
      # Represents programming constructs like variables, classes, interfaces etc.
      # that appear in a document. Document symbols can be hierarchical and they
      # have two ranges: one that encloses its definition and one that points to its
      # most interesting range, e.g. the range of an identifier.
      #
      class DocumentSymbol
        def initialize(name:, detail: nil, kind:, tags: nil, deprecated: nil, range:, selection_range:, children: nil)
          @attributes = {}

          @attributes[:name] = name
          @attributes[:detail] = detail if detail
          @attributes[:kind] = kind
          @attributes[:tags] = tags if tags
          @attributes[:deprecated] = deprecated if deprecated
          @attributes[:range] = range
          @attributes[:selectionRange] = selection_range
          @attributes[:children] = children if children

          @attributes.freeze
        end

        #
        # The name of this symbol. Will be displayed in the user interface and
        # therefore must not be an empty string or a string only consisting of
        # white spaces.
        #
        # @return [string]
        def name
          attributes.fetch(:name)
        end

        #
        # More detail for this symbol, e.g the signature of a function.
        #
        # @return [string]
        def detail
          attributes.fetch(:detail)
        end

        #
        # The kind of this symbol.
        #
        # @return [SymbolKind]
        def kind
          attributes.fetch(:kind)
        end

        #
        # Tags for this document symbol.
        #
        # @return [1[]]
        def tags
          attributes.fetch(:tags)
        end

        #
        # Indicates if this symbol is deprecated.
        #
        # @return [boolean]
        def deprecated
          attributes.fetch(:deprecated)
        end

        #
        # The range enclosing this symbol not including leading/trailing whitespace
        # but everything else like comments. This information is typically used to
        # determine if the clients cursor is inside the symbol to reveal in the
        # symbol in the UI.
        #
        # @return [Range]
        def range
          attributes.fetch(:range)
        end

        #
        # The range that should be selected and revealed when this symbol is being
        # picked, e.g. the name of a function. Must be contained by the `range`.
        #
        # @return [Range]
        def selection_range
          attributes.fetch(:selectionRange)
        end

        #
        # Children of this symbol, e.g. properties of a class.
        #
        # @return [DocumentSymbol[]]
        def children
          attributes.fetch(:children)
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
