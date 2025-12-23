# frozen_string_literal: true

# Try to require sidekiq-scheduler to make sure it's loaded before the integration.
begin
  require "sidekiq-scheduler"
rescue LoadError
  return
end

# If we've loaded sidekiq-scheduler, but the API changed,
# and the Scheduler class is not there, fail gracefully.
return unless defined?(::SidekiqScheduler::Scheduler)

module Sentry
  module SidekiqScheduler
    module Scheduler
      def new_job(name, interval_type, config, schedule, options)
        # Schedule the job upstream first
        # SidekiqScheduler does not validate schedules
        # It will fail with an error if the schedule in the config is invalid.
        # If this errors out, let it fall through.
        rufus_job = super

        klass = config.fetch("class")
        return rufus_job unless klass

        # Constantize the job class, and fail gracefully if it could not be found
        klass_const =
          begin
            Object.const_get(klass)
          rescue NameError
            return rufus_job
          end

        # For cron, every, or interval jobs — grab their schedule.
        # Rufus::Scheduler::EveryJob stores it's frequency in seconds,
        # so we convert it to minutes before passing in to the monitor.
        monitor_config =
          case interval_type
          when "cron"
            # fugit is a second order dependency of sidekiq-scheduler via rufus-scheduler
            parsed_cron = ::Fugit.parse_cron(schedule)
            timezone = parsed_cron.timezone

            # fugit supports having the timezone part of the cron string,
            # so we need to pull that with some hacky stuff
            if timezone
              parsed_cron.instance_variable_set(:@timezone, nil)
              cron_without_timezone = parsed_cron.to_cron_s
              Sentry::Cron::MonitorConfig.from_crontab(cron_without_timezone, timezone: timezone.name)
            else
              Sentry::Cron::MonitorConfig.from_crontab(schedule)
            end
          when "every", "interval"
            Sentry::Cron::MonitorConfig.from_interval(rufus_job.frequency.to_i / 60, :minute)
          end

        # If we couldn't build a monitor config, it's either an error, or
        # it's a one-time job (interval_type is in, or at), in which case
        # we should not make a monitof for it automaticaly.
        return rufus_job if monitor_config.nil?

        # only patch if not explicitly included in job by user
        unless klass_const.send(:ancestors).include?(Sentry::Cron::MonitorCheckIns)
          klass_const.send(:include, Sentry::Cron::MonitorCheckIns)
          slug = klass_const.send(:sentry_monitor_slug, name: name)
          klass_const.send(:sentry_monitor_check_ins,
                           slug: slug,
                           monitor_config: monitor_config)

          ::Sidekiq.logger.info "Injected Sentry Crons monitor checkins into #{klass}"
        end

        rufus_job
      end
    end
  end
end

Sentry.register_patch(:sidekiq_scheduler, Sentry::SidekiqScheduler::Scheduler, ::SidekiqScheduler::Scheduler)
