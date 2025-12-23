# frozen_string_literal: true

require_relative 'ext'

module Datadog
  module Tracing
    module Contrib
      module Propagation
        # Implements sql comment propagation related contracts.
        module SqlComment
          Mode = Struct.new(:mode, :append) do
            def enabled?
              service? || full?
            end

            def service?
              mode == Ext::SERVICE
            end

            def full?
              mode == Ext::FULL
            end

            def append?
              append
            end
          end
        end
      end
    end
  end
end
