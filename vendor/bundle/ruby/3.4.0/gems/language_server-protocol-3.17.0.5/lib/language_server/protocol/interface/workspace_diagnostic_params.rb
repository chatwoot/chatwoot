module LanguageServer
  module Protocol
    module Interface
      #
      # Parameters of the workspace diagnostic request.
      #
      class WorkspaceDiagnosticParams
        def initialize(work_done_token: nil, partial_result_token: nil, identifier: nil, previous_result_ids:)
          @attributes = {}

          @attributes[:workDoneToken] = work_done_token if work_done_token
          @attributes[:partialResultToken] = partial_result_token if partial_result_token
          @attributes[:identifier] = identifier if identifier
          @attributes[:previousResultIds] = previous_result_ids

          @attributes.freeze
        end

        #
        # An optional token that a server can use to report work done progress.
        #
        # @return [ProgressToken]
        def work_done_token
          attributes.fetch(:workDoneToken)
        end

        #
        # An optional token that a server can use to report partial results (e.g.
        # streaming) to the client.
        #
        # @return [ProgressToken]
        def partial_result_token
          attributes.fetch(:partialResultToken)
        end

        #
        # The additional identifier provided during registration.
        #
        # @return [string]
        def identifier
          attributes.fetch(:identifier)
        end

        #
        # The currently known diagnostic reports with their
        # previous result ids.
        #
        # @return [PreviousResultId[]]
        def previous_result_ids
          attributes.fetch(:previousResultIds)
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
