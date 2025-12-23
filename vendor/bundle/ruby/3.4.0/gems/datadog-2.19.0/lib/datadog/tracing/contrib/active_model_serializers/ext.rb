# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module ActiveModelSerializers
        # ActiveModelSerializers integration constants
        # @public_api Changing resource names, tag names, or environment variables creates breaking changes.
        module Ext
          ENV_ENABLED = 'DD_TRACE_ACTIVE_MODEL_SERIALIZERS_ENABLED'
          # @!visibility private
          ENV_ANALYTICS_ENABLED = 'DD_TRACE_ACTIVE_MODEL_SERIALIZERS_ANALYTICS_ENABLED'
          ENV_ANALYTICS_SAMPLE_RATE = 'DD_TRACE_ACTIVE_MODEL_SERIALIZERS_ANALYTICS_SAMPLE_RATE'
          SPAN_RENDER = 'active_model_serializers.render'
          SPAN_SERIALIZE = 'active_model_serializers.serialize'
          TAG_ADAPTER = 'active_model_serializers.adapter'
          TAG_COMPONENT = 'active_model_serializers'
          TAG_OPERATION_RENDER = 'render'
          TAG_OPERATION_SERIALIZE = 'serialize'
          TAG_SERIALIZER = 'active_model_serializers.serializer'
        end
      end
    end
  end
end
