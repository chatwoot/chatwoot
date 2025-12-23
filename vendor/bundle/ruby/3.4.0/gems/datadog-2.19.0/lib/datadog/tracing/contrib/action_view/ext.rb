# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module ActionView
        # ActionView integration constants
        # @public_api Changing resource names, tag names, or environment variables creates breaking changes.
        module Ext
          ENV_ENABLED = 'DD_TRACE_ACTION_VIEW_ENABLED'
          # @!visibility private
          ENV_ANALYTICS_ENABLED = 'DD_TRACE_ACTION_VIEW_ANALYTICS_ENABLED'
          ENV_ANALYTICS_SAMPLE_RATE = 'DD_TRACE_ACTION_VIEW_ANALYTICS_SAMPLE_RATE'
          SPAN_RENDER_PARTIAL = 'rails.render_partial'
          SPAN_RENDER_TEMPLATE = 'rails.render_template'
          TAG_COMPONENT = 'action_view'
          TAG_LAYOUT = 'rails.layout'
          TAG_OPERATION_RENDER_PARTIAL = 'render_partial'
          TAG_OPERATION_RENDER_TEMPLATE = 'render_template'
          TAG_TEMPLATE_NAME = 'rails.template_name'
        end
      end
    end
  end
end
