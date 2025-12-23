module LanguageServer
  module Protocol
    module Interface
      #
      # Represents information about programming constructs like variables, classes,
      # interfaces etc.
      #
      class SymbolInformation
        def initialize(name:, kind:, tags: nil, deprecated: nil, location:, container_name: nil)
          @attributes = {}

          @attributes[:name] = name
          @attributes[:kind] = kind
          @attributes[:tags] = tags if tags
          @attributes[:deprecated] = deprecated if deprecated
          @attributes[:location] = location
          @attributes[:containerName] = container_name if container_name

          @attributes.freeze
        end

        #
        # The name of this symbol.
        #
        # @return [string]
        def name
          attributes.fetch(:name)
        end

        #
        # The kind of this symbol.
        #
        # @return [SymbolKind]
        def kind
          attributes.fetch(:kind)
        end

        #
        # Tags for this symbol.
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
        # The location of this symbol. The location's range is used by a tool
        # to reveal the location in the editor. If the symbol is selected in the
        # tool the range's start information is used to position the cursor. So
        # the range usually spans more then the actual symbol's name and does
        # normally include things like visibility modifiers.
        #
        # The range doesn't have to denote a node range in the sense of an abstract
        # syntax tree. It can therefore not be used to re-construct a hierarchy of
        # the symbols.
        #
        # @return [Location]
        def location
          attributes.fetch(:location)
        end

        #
        # The name of the symbol containing this symbol. This information is for
        # user interface purposes (e.g. to render a qualifier in the user interface
        # if necessary). It can't be used to re-infer a hierarchy for the document
        # symbols.
        #
        # @return [string]
        def container_name
          attributes.fetch(:containerName)
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
