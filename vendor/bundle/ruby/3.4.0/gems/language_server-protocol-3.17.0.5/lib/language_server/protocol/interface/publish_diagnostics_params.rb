module LanguageServer
  module Protocol
    module Interface
      class PublishDiagnosticsParams
        def initialize(uri:, version: nil, diagnostics:)
          @attributes = {}

          @attributes[:uri] = uri
          @attributes[:version] = version if version
          @attributes[:diagnostics] = diagnostics

          @attributes.freeze
        end

        #
        # The URI for which diagnostic information is reported.
        #
        # @return [string]
        def uri
          attributes.fetch(:uri)
        end

        #
        # Optional the version number of the document the diagnostics are published
        # for.
        #
        # @return [number]
        def version
          attributes.fetch(:version)
        end

        #
        # An array of diagnostic information items.
        #
        # @return [Diagnostic[]]
        def diagnostics
          attributes.fetch(:diagnostics)
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
