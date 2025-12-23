# frozen_string_literal: true

require_relative '../patcher'

module Datadog
  module Tracing
    module Contrib
      module Sidekiq
        # Patcher enables patching of 'sidekiq' module.
        module Patcher
          include Contrib::Patcher

          module_function

          def target_version
            Integration.version
          end

          def patch
            require_relative 'client_tracer'
            require_relative 'server_tracer'

            ::Sidekiq.configure_client do |config|
              config.client_middleware do |chain|
                chain.add(Sidekiq::ClientTracer)
              end
            end

            ::Sidekiq.configure_server do |config|
              # If a job enqueues another job, make sure it has the same client
              # middleware.
              config.client_middleware do |chain|
                chain.add(Sidekiq::ClientTracer)
              end

              config.server_middleware do |chain|
                chain.add(Sidekiq::ServerTracer)
              end

              patch_server_internals if Integration.compatible_with_server_internal_tracing?
            end
          end

          def patch_server_internals
            patch_server_heartbeat
            patch_server_job_fetch
            patch_server_scheduled_push
            patch_redis_info
          end

          def patch_server_heartbeat
            require_relative 'server_internal_tracer/stop'
            require_relative 'server_internal_tracer/heartbeat'

            ::Sidekiq::Launcher.prepend(ServerInternalTracer::Stop)

            # Sidekiq 7 changed method `heartbeat` to `beat`
            if ::Sidekiq::Launcher.private_method_defined? :heartbeat
              ::Sidekiq::Launcher.prepend(ServerInternalTracer::Heartbeat)
            end

            ::Sidekiq::Launcher.prepend(ServerInternalTracer::Beat) if ::Sidekiq::Launcher.private_method_defined? :beat
          end

          def patch_server_job_fetch
            require_relative 'server_internal_tracer/job_fetch'

            ::Sidekiq::Processor.prepend(ServerInternalTracer::JobFetch)
          end

          def patch_server_scheduled_push
            require_relative 'server_internal_tracer/scheduled_poller'

            ::Sidekiq::Scheduled::Poller.prepend(ServerInternalTracer::ScheduledPoller)
          end

          def patch_redis_info
            require_relative 'server_internal_tracer/redis_info'

            if Integration.supports_capsules?
              ::Sidekiq::Config.prepend(ServerInternalTracer::RedisInfo)
            else
              ::Sidekiq.singleton_class.prepend(ServerInternalTracer::RedisInfo)
            end
          end
        end
      end
    end
  end
end
