# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module ActionCable
        # ActionCable integration constants
        # @public_api Changing resource names, tag names, or environment variables creates breaking changes.
        module Ext
          ENV_ENABLED = 'DD_TRACE_ACTION_CABLE_ENABLED'
          # @!visibility private
          ENV_ANALYTICS_ENABLED = 'DD_TRACE_ACTION_CABLE_ANALYTICS_ENABLED'
          ENV_ANALYTICS_SAMPLE_RATE = 'DD_TRACE_ACTION_CABLE_ANALYTICS_SAMPLE_RATE'
          SPAN_ACTION = 'action_cable.action'
          SPAN_BROADCAST = 'action_cable.broadcast'
          SPAN_ON_OPEN = 'action_cable.on_open'
          SPAN_TRANSMIT = 'action_cable.transmit'
          TAG_ACTION = 'action_cable.action'
          TAG_BROADCAST_CODER = 'action_cable.broadcast.coder'
          TAG_CHANNEL = 'action_cable.channel'
          TAG_CHANNEL_CLASS = 'action_cable.channel_class'
          TAG_COMPONENT = 'action_cable'
          TAG_CONNECTION = 'action_cable.connection'
          TAG_OPERATION_ACTION = 'action'
          TAG_OPERATION_BROADCAST = 'broadcast'
          TAG_OPERATION_ON_OPEN = 'on_open'
          TAG_OPERATION_TRANSMIT = 'transmit'
          TAG_TRANSMIT_VIA = 'action_cable.transmit.via'
        end
      end
    end
  end
end
