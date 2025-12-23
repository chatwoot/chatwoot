# frozen_string_literal: true

#
# Sidekiq's systemd integration allows Sidekiq to inform systemd:
#  1. when it has successfully started
#  2. when it is starting shutdown
#  3. periodically for a liveness check with a watchdog thread
#
module Sidekiq
  def self.start_watchdog
    usec = Integer(ENV["WATCHDOG_USEC"])
    return Sidekiq.logger.error("systemd Watchdog too fast: " + usec) if usec < 1_000_000

    sec_f = usec / 1_000_000.0
    # "It is recommended that a daemon sends a keep-alive notification message
    # to the service manager every half of the time returned here."
    ping_f = sec_f / 2
    Sidekiq.logger.info "Pinging systemd watchdog every #{ping_f.round(1)} sec"
    Thread.new do
      loop do
        sleep ping_f
        Sidekiq::SdNotify.watchdog
      end
    end
  end
end
