module LanguageServer
  module Protocol
    module Interface
      #
      # An unchanged diagnostic report with a set of related documents.
      #
      class RelatedUnchangedDocumentDiagnosticReport
        def initialize(kind:, result_id:, related_documents: nil)
          @attributes = {}

          @attributes[:kind] = kind
          @attributes[:resultId] = result_id
          @attributes[:relatedDocuments] = related_documents if related_documents

          @attributes.freeze
        end

        #
        # A document diagnostic report indicating
        # no changes to the last result. A server can
        # only return `unchanged` if result ids are
        # provided.
        #
        # @return [any]
        def kind
          attributes.fetch(:kind)
        end

        #
        # A result id which will be sent on the next
        # diagnostic request for the same document.
        #
        # @return [string]
        def result_id
          attributes.fetch(:resultId)
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
