# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

# This class is the central point for dispatching get_agent_commands messages
# to the various components that actually process them.
#
# This could be evented further, but we eventually need direct access to things
# like the ThreadProfiler, so it's simpler to just keep it together here.

require 'new_relic/agent/commands/agent_command'
require 'new_relic/agent/threading/backtrace_service'

module NewRelic
  module Agent
    module Commands
      class AgentCommandRouter
        attr_reader :handlers

        attr_accessor :thread_profiler_session, :backtrace_service

        def initialize(event_listener = nil)
          @handlers = Hash.new { |*| proc { |cmd| self.unrecognized_agent_command(cmd) } }

          @backtrace_service = Threading::BacktraceService.new(event_listener)

          @thread_profiler_session = ThreadProfilerSession.new(@backtrace_service)

          @handlers['start_profiler'] = proc { |cmd| thread_profiler_session.handle_start_command(cmd) }
          @handlers['stop_profiler'] = proc { |cmd| thread_profiler_session.handle_stop_command(cmd) }

          # the following statement needs else branch coverage
          if event_listener # rubocop:disable Style/SafeNavigation
            event_listener.subscribe(:before_shutdown, &method(:on_before_shutdown))
          end
        end

        def new_relic_service
          NewRelic::Agent.instance.service
        end

        def check_for_and_handle_agent_commands
          commands = get_agent_commands

          results = invoke_commands(commands)
          new_relic_service.agent_command_results(results) unless results.empty?
        end

        def on_before_shutdown(*args)
          if self.thread_profiler_session.running?
            self.thread_profiler_session.stop(true)
          end
        end

        def harvest!
          profiles = []
          profiles += harvest_from_thread_profiler_session
          log_profiles(profiles)
          profiles
        end

        # We don't currently support merging thread profiles that failed to send
        # back into the AgentCommandRouter, so we just no-op this method.
        # Same with reset! - we don't support asynchronous cancellation of a
        # running thread profile currently.
        def merge!(*args); end

        def reset!; end

        def harvest_from_thread_profiler_session
          if self.thread_profiler_session.ready_to_harvest?
            self.thread_profiler_session.stop(true)
            [self.thread_profiler_session.harvest]
          else
            []
          end
        end

        def log_profiles(profiles)
          if profiles.empty?
            ::NewRelic::Agent.logger.debug('No thread profiles with data found to send.')
          else
            profile_descriptions = profiles.map { |p| p.to_log_description }
            ::NewRelic::Agent.logger.debug("Sending thread profiles [#{profile_descriptions.join(', ')}]")
          end
        end

        def get_agent_commands
          commands = new_relic_service.get_agent_commands
          NewRelic::Agent.logger.debug("Received get_agent_commands = #{commands.inspect}")
          commands.map { |collector_command| AgentCommand.new(collector_command) }
        end

        def invoke_commands(agent_commands)
          results = {}

          agent_commands.each do |agent_command|
            results[agent_command.id.to_s] = invoke_command(agent_command)
          end

          results
        end

        class AgentCommandError < StandardError
        end

        def invoke_command(agent_command)
          begin
            call_handler_for(agent_command)
            return success
          rescue AgentCommandError => e
            NewRelic::Agent.logger.debug(e)
            error(e)
          end
        end

        SUCCESS_RESULT = NewRelic::EMPTY_HASH
        ERROR_KEY = 'error'

        def success
          SUCCESS_RESULT
        end

        def error(err)
          {ERROR_KEY => err.message}
        end

        def call_handler_for(agent_command)
          handler = select_handler(agent_command)
          handler.call(agent_command)
        end

        def select_handler(agent_command)
          @handlers[agent_command.name]
        end

        def unrecognized_agent_command(agent_command)
          NewRelic::Agent.logger.debug("Unrecognized agent command #{agent_command.inspect}")
        end
      end
    end
  end
end
