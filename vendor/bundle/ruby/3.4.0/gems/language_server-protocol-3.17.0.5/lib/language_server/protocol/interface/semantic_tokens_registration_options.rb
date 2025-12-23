module LanguageServer
  module Protocol
    module Interface
      class SemanticTokensRegistrationOptions
        def initialize(document_selector:, work_done_progress: nil, legend:, range: nil, full: nil, id: nil)
          @attributes = {}

          @attributes[:documentSelector] = document_selector
          @attributes[:workDoneProgress] = work_done_progress if work_done_progress
          @attributes[:legend] = legend
          @attributes[:range] = range if range
          @attributes[:full] = full if full
          @attributes[:id] = id if id

          @attributes.freeze
        end

        #
        # A document selector to identify the scope of the registration. If set to
        # null the document selector provided on the client side will be used.
        #
        # @return [DocumentSelector]
        def document_selector
          attributes.fetch(:documentSelector)
        end

        # @return [boolean]
        def work_done_progress
          attributes.fetch(:workDoneProgress)
        end

        #
        # The legend used by the server
        #
        # @return [SemanticTokensLegend]
        def legend
          attributes.fetch(:legend)
        end

        #
        # Server supports providing semantic tokens for a specific range
        # of a document.
        #
        # @return [boolean | {}]
        def range
          attributes.fetch(:range)
        end

        #
        # Server supports providing semantic tokens for a full document.
        #
        # @return [boolean | { delta?: boolean; }]
        def full
          attributes.fetch(:full)
        end

        #
        # The id used to register the request. The id can be used to deregister
        # the request again. See also Registration#id.
        #
        # @return [string]
        def id
          attributes.fetch(:id)
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
