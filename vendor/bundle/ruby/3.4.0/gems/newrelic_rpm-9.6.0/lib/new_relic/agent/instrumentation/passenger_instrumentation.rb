# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

DependencyDetection.defer do
  @name = :passenger

  depends_on do
    defined?(PhusionPassenger)
  end

  executes do
    NewRelic::Agent.logger.debug('Installing Passenger event hooks.')

    PhusionPassenger.on_event(:stopping_worker_process) do
      NewRelic::Agent.logger.debug('Passenger stopping this process, shutdown the agent.')
      NewRelic::Agent.instance.shutdown
    end

    PhusionPassenger.on_event(:starting_worker_process) do |forked|
      # We want to reset the stats from the stats engine in case any carried
      # over into the spawned process.  Don't clear them in case any were
      # cached.  We do this even in conservative spawning.
      NewRelic::Agent.after_fork(:force_reconnect => true)
    end
  end
end
