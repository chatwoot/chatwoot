# frozen_string_literal: true

require_relative 'worker'
require_relative 'client/capabilities'
require_relative 'client'
require_relative 'transport/http'
require_relative '../remote'
require_relative 'negotiation'

module Datadog
  module Core
    module Remote
      # Configures the HTTP transport to communicate with the agent
      # to fetch and sync the remote configuration
      class Component
        attr_reader :logger, :client, :healthy

        def initialize(settings, capabilities, agent_settings, logger:)
          @logger = logger

          negotiation = Negotiation.new(settings, agent_settings, logger: logger)
          transport_v7 = Datadog::Core::Remote::Transport::HTTP.v7(agent_settings: agent_settings, logger: logger)

          @barrier = Barrier.new(settings.remote.boot_timeout_seconds)

          @client = Client.new(transport_v7, capabilities, logger: logger)
          @healthy = false
          logger.debug { "new remote configuration client: #{@client.id}" }

          @worker = Worker.new(interval: settings.remote.poll_interval_seconds, logger: logger) do
            unless @healthy || negotiation.endpoint?('/v0.7/config')
              @barrier.lift

              next
            end

            begin
              @client.sync
              @healthy ||= true
            rescue Client::SyncError => e
              # Transient errors due to network or agent. Logged the error but not via telemetry
              logger.error do
                "remote worker client sync error: #{e.message} location: #{Array(e.backtrace).first}. skipping sync"
              end
            rescue => e
              # In case of unexpected errors, reset the negotiation object
              # given external conditions have changed and the negotiation
              # negotiation object stores error logging state that should be reset.
              negotiation = Negotiation.new(settings, agent_settings, logger: logger)

              # Transient errors due to network or agent. Logged the error but not via telemetry
              logger.error do
                "remote worker error: #{e.class.name} #{e.message} location: #{Array(e.backtrace).first}. " \
                'resetting client state'
              end

              # client state is unknown, state might be corrupted
              @client = Client.new(transport_v7, capabilities, logger: logger)
              @healthy = false
              logger.debug { "new remote configuration client: #{@client.id}" }

              # TODO: bail out if too many errors?
            end

            @barrier.lift
          end
        end

        # Starts the Remote Configuration worker without waiting for first run
        def start
          @worker.start
        end

        # Is the Remote Configuration worker running?
        def started?
          @worker.started?
        end

        # If the worker is not initialized, initialize it.
        #
        # Then, waits for one client sync to be executed if `kind` is `:once`.
        def barrier(_kind)
          start
          @barrier.wait_once
        end

        def shutdown!
          @worker.stop
        end

        # Barrier provides a mechanism to fence execution until a condition happens
        class Barrier
          def initialize(timeout = nil)
            @once = false
            @timeout = timeout

            @mutex = Mutex.new
            @condition = ConditionVariable.new
          end

          # Wait for first lift to happen, otherwise don't wait
          def wait_once(timeout = nil)
            # TTAS (Test and Test-And-Set) optimisation
            # Since @once only ever goes from false to true, this is semantically valid
            return :pass if @once

            begin
              @mutex.lock

              return :pass if @once

              timeout ||= @timeout

              # - starting with Ruby 3.2, ConditionVariable#wait returns nil on
              #   timeout and an integer otherwise
              # - before Ruby 3.2, ConditionVariable returns itself
              # so we have to rely on @once having been set
              if RUBY_VERSION >= '3.2'
                lifted = @condition.wait(@mutex, timeout)
              else
                @condition.wait(@mutex, timeout)
                lifted = @once
              end

              if lifted
                :lift
              else
                @once = true
                :timeout
              end
            ensure
              @mutex.unlock
            end
          end

          # Release all current waiters
          def lift
            @mutex.lock

            @once ||= true

            @condition.broadcast
          ensure
            @mutex.unlock
          end
        end

        class << self
          # Because the agent might not be available yet, we can't perform agent-specific checks yet, as they
          # would prevent remote configuration from ever running.
          #
          # Those checks are instead performed inside the worker loop.
          # This allows users to upgrade their agent while keeping their application running.
          def build(settings, agent_settings, logger:, telemetry:)
            return unless settings.remote.enabled

            new(settings, Client::Capabilities.new(settings, telemetry), agent_settings, logger: logger)
          end
        end
      end
    end
  end
end
