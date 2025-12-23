module LanguageServer
  module Protocol
    module Interface
      #
      # Moniker definition to match LSIF 0.5 moniker definition.
      #
      class Moniker
        def initialize(scheme:, identifier:, unique:, kind: nil)
          @attributes = {}

          @attributes[:scheme] = scheme
          @attributes[:identifier] = identifier
          @attributes[:unique] = unique
          @attributes[:kind] = kind if kind

          @attributes.freeze
        end

        #
        # The scheme of the moniker. For example tsc or .Net
        #
        # @return [string]
        def scheme
          attributes.fetch(:scheme)
        end

        #
        # The identifier of the moniker. The value is opaque in LSIF however
        # schema owners are allowed to define the structure if they want.
        #
        # @return [string]
        def identifier
          attributes.fetch(:identifier)
        end

        #
        # The scope in which the moniker is unique
        #
        # @return [UniquenessLevel]
        def unique
          attributes.fetch(:unique)
        end

        #
        # The moniker kind if known.
        #
        # @return [MonikerKind]
        def kind
          attributes.fetch(:kind)
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
