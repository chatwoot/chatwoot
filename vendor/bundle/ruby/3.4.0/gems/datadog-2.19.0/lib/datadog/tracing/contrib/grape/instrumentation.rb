# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module Grape
        # Instrumentation for Grape::Endpoint
        module Instrumentation
          def self.included(base)
            base.singleton_class.prepend(ClassMethods)
            base.prepend(InstanceMethods)
          end

          # ClassMethods - implementing instrumentation
          module ClassMethods
            def generate_api_method(*params, &block)
              method_api = super

              proc do |*args|
                ::ActiveSupport::Notifications.instrument('endpoint_render.grape.start_render')
                method_api.call(*args)
              end
            end
          end

          # InstanceMethods - implementing instrumentation
          module InstanceMethods
            def run(*args)
              ::ActiveSupport::Notifications.instrument('endpoint_run.grape.start_process', endpoint: self, env: env)
              super
            end
          end
        end
      end
    end
  end
end
