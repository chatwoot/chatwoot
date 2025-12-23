module LanguageServer
  module Protocol
    module Interface
      #
      # A full diagnostic report with a set of related documents.
      #
      class RelatedFullDocumentDiagnosticReport
        def initialize(kind:, result_id: nil, items:, related_documents: nil)
          @attributes = {}

          @attributes[:kind] = kind
          @attributes[:resultId] = result_id if result_id
          @attributes[:items] = items
          @attributes[:relatedDocuments] = related_documents if related_documents

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
        # Diagnostics of related documents. This information is useful
        # in programming languages where code in a file A can generate
        # diagnostics in a file B which A depends on. An example of
        # such a language is C/C++ where marco definitions in a file
        # a.cpp and result in errors in a header file b.hpp.
        #
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
