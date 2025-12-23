# frozen_string_literal: true

require_relative '../patcher'
require_relative 'action_tracer'
require_relative 'renderer_policy_tracing'
require_relative 'router_tracing'

module Datadog
  module Tracing
    module Contrib
      module Hanami
        # Patcher enables patching of Hanami
        module Patcher
          include Contrib::Patcher

          module_function

          def target_version
            Integration.version
          end

          def patch
            # For auto instrumentation, `plugin` must be required before `Hanami.boot`
            require_relative 'plugin'

            ::Hanami::Router.prepend(RouterTracing)
            ::Hanami::RenderingPolicy.prepend(RendererPolicyTracing)
          end
        end
      end
    end
  end
end
