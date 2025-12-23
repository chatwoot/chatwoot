require 'sidekiq/cron/poller'

# For Cron we need to add some methods to Launcher
# so look at the code bellow.
#
# We are creating new cron poller instance and
# adding start and stop commands to launcher.
module Sidekiq
  module Cron
    module Launcher
      DEFAULT_POLL_INTERVAL = 30

      # Add cron poller to launcher.
      attr_reader :cron_poller

      # Add cron poller and execute normal initialize of Sidekiq launcher.
      def initialize(config, **kwargs)
        config[:cron_poll_interval] = DEFAULT_POLL_INTERVAL if config[:cron_poll_interval].nil?

        @cron_poller = Sidekiq::Cron::Poller.new(config) if config[:cron_poll_interval] > 0
        super
      end

      # Execute normal run of launcher and run cron poller.
      def run
        super
        cron_poller.start if @cron_poller
      end

      # Execute normal quiet of launcher and quiet cron poller.
      def quiet
        cron_poller.terminate if @cron_poller
        super
      end

      # Execute normal stop of launcher and stop cron poller.
      def stop
        cron_poller.terminate if @cron_poller
        super
      end
    end
  end
end

Sidekiq.configure_server do
  require 'sidekiq/launcher'

  ::Sidekiq::Launcher.prepend(Sidekiq::Cron::Launcher)
end
