module LanguageServer
  module Protocol
    module Interface
      #
      # A special workspace symbol that supports locations without a range
      #
      class WorkspaceSymbol
        def initialize(name:, kind:, tags: nil, container_name: nil, location:, data: nil)
          @attributes = {}

          @attributes[:name] = name
          @attributes[:kind] = kind
          @attributes[:tags] = tags if tags
          @attributes[:containerName] = container_name if container_name
          @attributes[:location] = location
          @attributes[:data] = data if data

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
        # Tags for this completion item.
        #
        # @return [1[]]
        def tags
          attributes.fetch(:tags)
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

        #
        # The location of this symbol. Whether a server is allowed to
        # return a location without a range depends on the client
        # capability `workspace.symbol.resolveSupport`.
        #
        # See also `SymbolInformation.location`.
        #
        # @return [Location | { uri: string; }]
        def location
          attributes.fetch(:location)
        end

        #
        # A data entry field that is preserved on a workspace symbol between a
        # workspace symbol request and a workspace symbol resolve request.
        #
        # @return [LSPAny]
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
