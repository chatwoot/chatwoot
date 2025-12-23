# frozen_string_literal: true

# Try requiring sidekiq-cron to ensure it's loaded before the integration.
# If sidekiq-cron is not available, do nothing.
begin
  require "sidekiq-cron"
rescue LoadError
  return
end

module Sentry
  module Sidekiq
    module Cron
      module Job
        def save
          # validation failed, do nothing
          return false unless super

          # fail gracefully if can't find class
          klass_const =
            begin
              ::Sidekiq::Cron::Support.constantize(klass.to_s)
            rescue NameError
              return true
            end

          # only patch if not explicitly included in job by user
          unless klass_const.send(:ancestors).include?(Sentry::Cron::MonitorCheckIns)
            klass_const.send(:include, Sentry::Cron::MonitorCheckIns)
            klass_const.send(:sentry_monitor_check_ins,
                             slug: name,
                             monitor_config: Sentry::Cron::MonitorConfig.from_crontab(cron))
          end

          true
        end
      end
    end
  end
end

Sentry.register_patch(:sidekiq_cron, Sentry::Sidekiq::Cron::Job, ::Sidekiq::Cron::Job)
