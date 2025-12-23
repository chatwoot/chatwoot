module LanguageServer
  module Protocol
    module Interface
      class ExecutionSummary
        def initialize(execution_order:, success: nil)
          @attributes = {}

          @attributes[:executionOrder] = execution_order
          @attributes[:success] = success if success

          @attributes.freeze
        end

        #
        # A strict monotonically increasing value
        # indicating the execution order of a cell
        # inside a notebook.
        #
        # @return [number]
        def execution_order
          attributes.fetch(:executionOrder)
        end

        #
        # Whether the execution was successful or
        # not if known by the client.
        #
        # @return [boolean]
        def success
          attributes.fetch(:success)
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
