# frozen_string_literal: true

require_relative '../plugin'

# Puma's systemd integration allows Puma to inform systemd:
#  1. when it has successfully started
#  2. when it is starting shutdown
#  3. periodically for a liveness check with a watchdog thread
#  4. periodically set the status
Puma::Plugin.create do
  def start(launcher)
    require_relative '../sd_notify'

    launcher.log_writer.log "* Enabling systemd notification integration"

    # hook_events
    launcher.events.on_booted { Puma::SdNotify.ready }
    launcher.events.on_stopped { Puma::SdNotify.stopping }
    launcher.events.on_restart { Puma::SdNotify.reloading }

    # start watchdog
    if Puma::SdNotify.watchdog?
      ping_f = watchdog_sleep_time

      in_background do
        launcher.log_writer.log "Pinging systemd watchdog every #{ping_f.round(1)} sec"
        loop do
          sleep ping_f
          Puma::SdNotify.watchdog
        end
      end
    end

    # start status loop
    instance = self
    sleep_time = 1.0
    in_background do
      launcher.log_writer.log "Sending status to systemd every #{sleep_time.round(1)} sec"

      loop do
        sleep sleep_time
        # TODO: error handling?
        Puma::SdNotify.status(instance.status)
      end
    end
  end

  def status
    if clustered?
      messages = stats[:worker_status].map do |worker|
        common_message(worker[:last_status])
      end.join(',')

      "Puma #{Puma::Const::VERSION}: cluster: #{booted_workers}/#{workers}, worker_status: [#{messages}]"
    else
      "Puma #{Puma::Const::VERSION}: worker: #{common_message(stats)}"
    end
  end

  private

  def watchdog_sleep_time
    usec = Integer(ENV["WATCHDOG_USEC"])

    sec_f = usec / 1_000_000.0
    # "It is recommended that a daemon sends a keep-alive notification message
    # to the service manager every half of the time returned here."
    sec_f / 2
  end

  def stats
    Puma.stats_hash
  end

  def clustered?
    stats.has_key?(:workers)
  end

  def workers
    stats.fetch(:workers, 1)
  end

  def booted_workers
    stats.fetch(:booted_workers, 1)
  end

  def common_message(stats)
    "{ #{stats[:running]}/#{stats[:max_threads]} threads, #{stats[:pool_capacity]} available, #{stats[:backlog]} backlog }"
  end
end
