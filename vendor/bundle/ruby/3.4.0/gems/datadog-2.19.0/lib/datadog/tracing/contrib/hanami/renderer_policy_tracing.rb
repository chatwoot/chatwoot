# frozen_string_literal: true

require_relative 'ext'
require_relative '../../metadata/ext'

module Datadog
  module Tracing
    module Contrib
      module Hanami
        # Hanami Instrumentation for `hanami.render`
        module RendererPolicyTracing
          def render(env, response)
            action = env['hanami.action']
            # env['hanami.action'] could be empty for endpoints without an action
            #
            # For example in config/routes.rb:
            # get '/hello', to: ->(env) { [200, {}, ['Hello from Hanami!']] }
            action_klass = (action && action.class) ||
              ::Hanami::Routing::Default::NullAction

            Tracing.trace(
              Ext::SPAN_RENDER,
              service: configuration[:service_name],
              resource: action_klass.to_s,
              type: Tracing::Metadata::Ext::HTTP::TYPE_INBOUND
            ) do |span_op, _trace_op|
              span_op.set_tag(Tracing::Metadata::Ext::TAG_COMPONENT, Ext::TAG_COMPONENT)
              span_op.set_tag(Tracing::Metadata::Ext::TAG_OPERATION, Ext::TAG_OPERATION_RENDER)

              super
            end
          end

          def configuration
            Datadog.configuration.tracing[:hanami]
          end
        end
      end
    end
  end
end
