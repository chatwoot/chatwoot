module LanguageServer
  module Protocol
    module Interface
      #
      # A diagnostic report indicating that the last returned
      # report is still accurate.
      #
      class UnchangedDocumentDiagnosticReport
        def initialize(kind:, result_id:)
          @attributes = {}

          @attributes[:kind] = kind
          @attributes[:resultId] = result_id

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
