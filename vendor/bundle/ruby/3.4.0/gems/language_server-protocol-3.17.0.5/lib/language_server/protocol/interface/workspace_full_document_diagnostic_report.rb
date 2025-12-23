module LanguageServer
  module Protocol
    module Interface
      #
      # A full document diagnostic report for a workspace diagnostic result.
      #
      class WorkspaceFullDocumentDiagnosticReport
        def initialize(kind:, result_id: nil, items:, uri:, version:)
          @attributes = {}

          @attributes[:kind] = kind
          @attributes[:resultId] = result_id if result_id
          @attributes[:items] = items
          @attributes[:uri] = uri
          @attributes[:version] = version

          @attributes.freeze
        end

        #
        # A full document diagnostic report.
        #
        # @return [any]
        def kind
          attributes.fetch(:kind)
        end

        #
        # An optional result id. If provided it will
        # be sent on the next diagnostic request for the
        # same document.
        #
        # @return [string]
        def result_id
          attributes.fetch(:resultId)
        end

        #
        # The actual items.
        #
        # @return [Diagnostic[]]
        def items
          attributes.fetch(:items)
        end

        #
        # The URI for which diagnostic information is reported.
        #
        # @return [string]
        def uri
          attributes.fetch(:uri)
        end

        #
        # The version number for which the diagnostics are reported.
        # If the document is not marked as open `null` can be provided.
        #
        # @return [number]
        def version
          attributes.fetch(:version)
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
