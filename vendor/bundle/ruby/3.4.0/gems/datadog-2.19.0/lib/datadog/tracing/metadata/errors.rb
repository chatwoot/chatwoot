# frozen_string_literal: true

require_relative '../../core/error'

require_relative 'ext'

module Datadog
  module Tracing
    module Metadata
      # Adds error tagging behavior
      # @public_api
      module Errors
        def set_error(error)
          Datadog::Core.log_deprecation do
            'Errors.set_error(..) is deprecated. ' \
            'Use Errors.set_error_tags(..) instead.'
          end
          set_error_tags(error)
        end

        # Mark the span with the given error.
        def set_error_tags(error)
          e = Core::Error.build_from(error)

          set_tag(Ext::Errors::TAG_TYPE, e.type) unless e.type.empty?
          set_tag(Ext::Errors::TAG_MSG, e.message) unless e.message.empty?
          set_tag(Ext::Errors::TAG_STACK, e.backtrace) unless e.backtrace.empty?
        end
      end
    end
  end
end
