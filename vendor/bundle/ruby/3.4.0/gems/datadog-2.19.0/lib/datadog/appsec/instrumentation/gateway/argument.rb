# frozen_string_literal: true

module Datadog
  module AppSec
    module Instrumentation
      class Gateway
        # Base class for Gateway Arguments
        class Argument; end # rubocop:disable Lint/EmptyClass

        # Gateway User argument
        # NOTE: This class is a subject of elimination and will be removed when
        #       the event system is refactored.
        class User < Argument
          attr_reader :id, :login, :session_id

          def initialize(id = nil, login = nil, session_id = nil)
            super()

            @id = id
            @login = login
            @session_id = session_id
          end
        end
      end
    end
  end
end
