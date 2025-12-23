# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module ActionPack
        # ActionPack integration constants
        # @public_api Changing resource names, tag names, or environment variables creates breaking changes.
        module Ext
          ENV_ENABLED = 'DD_TRACE_ACTION_PACK_ENABLED'
          # @!visibility private
          ENV_ANALYTICS_ENABLED = 'DD_TRACE_ACTION_PACK_ANALYTICS_ENABLED'
          ENV_ANALYTICS_SAMPLE_RATE = 'DD_TRACE_ACTION_PACK_ANALYTICS_SAMPLE_RATE'
          SPAN_ACTION_CONTROLLER = 'rails.action_controller'
          TAG_COMPONENT = 'action_pack'
          TAG_OPERATION_CONTROLLER = 'controller'
          TAG_ROUTE_ACTION = 'rails.route.action'
          TAG_ROUTE_CONTROLLER = 'rails.route.controller'
          TAG_DB_RUNTIME = 'rails.db.runtime'
          TAG_VIEW_RUNTIME = 'rails.view.runtime'
        end
      end
    end
  end
end
