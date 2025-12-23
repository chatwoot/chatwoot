# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    module AgentHelpers
      module SpecialStartup
        # If we're using a dispatcher that forks before serving
        # requests, we need to wait until the children are forked
        # before connecting, otherwise the parent process sends useless data
        def using_forking_dispatcher?
          if [:puma, :passenger, :unicorn].include?(Agent.config[:dispatcher])
            ::NewRelic::Agent.logger.info('Deferring startup of agent reporting thread because ' \
              "#{Agent.config[:dispatcher]} may fork.")
            true
          else
            false
          end
        end

        # Return true if we're using resque and it hasn't had a chance to (potentially)
        # daemonize itself. This avoids hanging when there's a Thread started
        # before Resque calls Process.daemon (Jira RUBY-857)
        def defer_for_resque?
          NewRelic::Agent.config[:dispatcher] == :resque &&
            NewRelic::Agent::Instrumentation::Resque::Helper.resque_fork_per_job? &&
            !PipeChannelManager.listener.started?
        end

        def in_resque_child_process?
          defined?(@service) && @service.is_a?(PipeService)
        end

        def defer_for_delayed_job?
          NewRelic::Agent.config[:dispatcher] == :delayed_job &&
            !NewRelic::DelayedJobInjection.worker_name
        end

        # This matters when the following three criteria are met:
        #
        # 1. A Sinatra 'classic' application is being run
        # 2. The app is being run by executing the main file directly, rather
        #    than via a config.ru file.
        # 3. newrelic_rpm is required *after* sinatra
        #
        # In this case, the entire application runs from an at_exit handler in
        # Sinatra, and if we were to install ours, it would be executed before
        # the one in Sinatra, meaning that we'd shutdown the agent too early
        # and never collect any data.
        def sinatra_classic_app?
          (
            defined?(Sinatra::Application) &&
            Sinatra::Application.respond_to?(:run) &&
            Sinatra::Application.run?
          )
        end

        def should_install_exit_handler?
          return false unless Agent.config[:send_data_on_exit]

          !sinatra_classic_app? || Agent.config[:force_install_exit_handler]
        end

        def install_exit_handler
          return unless should_install_exit_handler?

          NewRelic::Agent.logger.debug('Installing at_exit handler')
          at_exit { shutdown }
        end
      end
    end
  end
end
