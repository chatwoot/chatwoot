module LanguageServer
  module Protocol
    module Interface
      #
      # A partial result for a document diagnostic report.
      #
      class DocumentDiagnosticReportPartialResult
        def initialize(related_documents:)
          @attributes = {}

          @attributes[:relatedDocuments] = related_documents

          @attributes.freeze
        end

        # @return [{ [uri: string]: FullDocumentDiagnosticReport | UnchangedDocumentDiagnosticReport; }]
        def related_documents
          attributes.fetch(:relatedDocuments)
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
