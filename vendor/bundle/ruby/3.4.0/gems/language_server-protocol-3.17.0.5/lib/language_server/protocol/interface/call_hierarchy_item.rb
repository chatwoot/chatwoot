module LanguageServer
  module Protocol
    module Interface
      class CallHierarchyItem
        def initialize(name:, kind:, tags: nil, detail: nil, uri:, range:, selection_range:, data: nil)
          @attributes = {}

          @attributes[:name] = name
          @attributes[:kind] = kind
          @attributes[:tags] = tags if tags
          @attributes[:detail] = detail if detail
          @attributes[:uri] = uri
          @attributes[:range] = range
          @attributes[:selectionRange] = selection_range
          @attributes[:data] = data if data

          @attributes.freeze
        end

        #
        # The name of this item.
        #
        # @return [string]
        def name
          attributes.fetch(:name)
        end

        #
        # The kind of this item.
        #
        # @return [SymbolKind]
        def kind
          attributes.fetch(:kind)
        end

        #
        # Tags for this item.
        #
        # @return [1[]]
        def tags
          attributes.fetch(:tags)
        end

        #
        # More detail for this item, e.g. the signature of a function.
        #
        # @return [string]
        def detail
          attributes.fetch(:detail)
        end

        #
        # The resource identifier of this item.
        #
        # @return [string]
        def uri
          attributes.fetch(:uri)
        end

        #
        # The range enclosing this symbol not including leading/trailing whitespace
        # but everything else, e.g. comments and code.
        #
        # @return [Range]
        def range
          attributes.fetch(:range)
        end

        #
        # The range that should be selected and revealed when this symbol is being
        # picked, e.g. the name of a function. Must be contained by the
        # [`range`](#CallHierarchyItem.range).
        #
        # @return [Range]
        def selection_range
          attributes.fetch(:selectionRange)
        end

        #
        # A data entry field that is preserved between a call hierarchy prepare and
        # incoming calls or outgoing calls requests.
        #
        # @return [unknown]
        def data
          attributes.fetch(:data)
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
