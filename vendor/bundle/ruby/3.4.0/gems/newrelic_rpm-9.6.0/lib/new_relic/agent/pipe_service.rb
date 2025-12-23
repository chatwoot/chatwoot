# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    class PipeService
      attr_reader :channel_id, :buffer, :pipe
      attr_accessor :request_timeout, :agent_id, :collector

      def initialize(channel_id)
        @channel_id = channel_id
        @collector = NewRelic::Control::Server.new({name: 'parent', port: 0})
        @pipe = NewRelic::Agent::PipeChannelManager.channels[@channel_id]
        if @pipe && @pipe.parent_pid != $$
          @pipe.after_fork_in_child
        else
          NewRelic::Agent.logger.error('No communication channel to parent process, please see https://docs.newrelic.com/docs/apm/agents/ruby-agent/background-jobs/resque-instrumentation/ for more information.')
        end
      end

      def connect(config)
        nil
      end

      def get_agent_commands
        NewRelic::EMPTY_ARRAY
      end

      def analytic_event_data(events)
        write_to_pipe(:analytic_event_data, events) if events
      end

      def custom_event_data(events)
        write_to_pipe(:custom_event_data, events) if events
      end

      def metric_data(unsent_timeslice_data)
        write_to_pipe(:metric_data, unsent_timeslice_data)
        {}
      end

      def transaction_sample_data(transactions)
        write_to_pipe(:transaction_sample_data, transactions) if transactions
      end

      def error_data(errors)
        write_to_pipe(:error_data, errors) if errors
      end

      def error_event_data(events)
        write_to_pipe(:error_event_data, events) if events
      end

      def span_event_data(events)
        write_to_pipe(:span_event_data, events) if events
      end

      def sql_trace_data(sql)
        write_to_pipe(:sql_trace_data, sql) if sql
      end

      def log_event_data(logs)
        write_to_pipe(:log_event_data, logs) if logs
      end

      def shutdown
        # no else branch coverage
        @pipe.close if @pipe # rubocop:disable Style/SafeNavigation
      end

      # Invokes the block it is passed.  This is used to implement HTTP
      # keep-alive in the NewRelicService, and is a required interface for any
      # Service class.
      def session
        yield
      end

      private

      def marshal_payload(data)
        Marshal.dump(data)
      end

      def write_to_pipe(endpoint, data)
        # the following line needs else branch coverage
        @pipe.write(marshal_payload([endpoint, data])) if @pipe # rubocop:disable Style/SafeNavigation
      end
    end
  end
end
