# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module Hanami
        # Hanami integration constants
        # @public_api Changing resource names, tag names, or environment variables creates breaking changes.
        module Ext
          ENV_ENABLED = 'DD_TRACE_HANAMI_ENABLED'

          SPAN_ACTION =  'hanami.action'
          SPAN_ROUTING = 'hanami.routing'
          SPAN_RENDER =  'hanami.render'

          TAG_COMPONENT = 'hanami'
          TAG_OPERATION_ACTION = 'action'
          TAG_OPERATION_ROUTING = 'routing'
          TAG_OPERATION_RENDER = 'render'
        end
      end
    end
  end
end
