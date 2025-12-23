module LanguageServer
  module Protocol
    module Interface
      #
      # A diagnostic report with a full set of problems.
      #
      class FullDocumentDiagnosticReport
        def initialize(kind:, result_id: nil, items:)
          @attributes = {}

          @attributes[:kind] = kind
          @attributes[:resultId] = result_id if result_id
          @attributes[:items] = items

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
