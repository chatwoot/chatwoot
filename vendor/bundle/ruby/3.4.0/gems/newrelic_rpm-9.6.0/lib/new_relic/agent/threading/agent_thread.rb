# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    module Threading
      class AgentThread
        def self.create(label, &blk)
          ::NewRelic::Agent.logger.debug("Creating AgentThread: #{label}")
          wrapped_blk = proc do
            if ::Thread.current[:newrelic_tracer_state] && Thread.current[:newrelic_tracer_state].current_transaction
              txn = ::Thread.current[:newrelic_tracer_state].current_transaction
              ::NewRelic::Agent.logger.warn("AgentThread created with current transaction #{txn.best_name}")
            end
            begin
              yield
            rescue => e
              ::NewRelic::Agent.logger.error("AgentThread #{label} exited with error", e)
            rescue Exception => e
              ::NewRelic::Agent.logger.error("AgentThread #{label} exited with exception. Re-raising in case of interrupt.", e)
              raise
            ensure
              ::NewRelic::Agent.logger.debug("Exiting AgentThread: #{label}")
            end
          end
          thread = nil
          NewRelic::Agent.disable_all_tracing { thread = backing_thread_class.new(&wrapped_blk) }
          thread[:newrelic_label] = label
          thread
        end

        # Simplifies testing if we don't directly use ::Thread.list, so keep
        # the accessor for it here on AgentThread to use and stub.
        def self.list
          backing_thread_class.list
        end

        def self.bucket_thread(thread, profile_agent_code) # THREAD_LOCAL_ACCESS
          if thread.key?(:newrelic_label)
            profile_agent_code ? :agent : :ignore
          else
            state = Tracer.state_for(thread)
            txn = state.current_transaction

            if txn && !txn.recording_web_transaction?
              :background
            elsif txn&.recording_web_transaction?
              :request
            else
              :other
            end
          end
        end

        def self.scrub_backtrace(thread, profile_agent_code)
          begin
            bt = thread.backtrace
          rescue Exception => e
            ::NewRelic::Agent.logger.debug("Failed to backtrace #{thread.inspect}: #{e.class.name}: #{e.to_s}")
          end
          return nil unless bt

          bt.reject! { |t| t.include?('/newrelic_rpm-') } unless profile_agent_code
          bt
        end

        # To allow tests to swap out Thread for a synchronous alternative,
        # surface the backing class we'll use from the class level.
        @backing_thread_class = ::Thread

        def self.backing_thread_class
          @backing_thread_class
        end

        def self.backing_thread_class=(clazz)
          @backing_thread_class = clazz
        end
      end
    end
  end
end
