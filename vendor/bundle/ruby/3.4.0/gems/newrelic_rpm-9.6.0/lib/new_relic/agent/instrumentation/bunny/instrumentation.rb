# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    module Instrumentation
      module Bunny
        module_function

        LIBRARY = 'RabbitMQ'
        DEFAULT_NAME = 'Default'
        DEFAULT_TYPE = :direct
        SLASH = '/'
        INSTRUMENTATION_NAME = NewRelic::Agent.base_name(name)

        def exchange_name(name)
          name.empty? ? DEFAULT_NAME : name
        end

        def exchange_type(delivery_info, channel)
          if di_exchange = delivery_info[:exchange]
            return DEFAULT_TYPE if di_exchange.empty?
            return channel.exchanges[delivery_info[:exchange]].type if channel.exchanges[di_exchange]
          end
        end

        module Exchange
          include Bunny

          def publish_with_tracing(payload, opts = {})
            NewRelic::Agent.record_instrumentation_invocation(INSTRUMENTATION_NAME)

            begin
              destination = exchange_name(name)

              tracing_enabled =
                NewRelic::Agent::CrossAppTracing.cross_app_enabled? ||
                NewRelic::Agent.config[:'distributed_tracing.enabled']
              opts[:headers] ||= {} if tracing_enabled

              segment = NewRelic::Agent::Messaging.start_amqp_publish_segment(
                library: LIBRARY,
                destination_name: destination,
                headers: opts[:headers],
                routing_key: opts[:routing_key] || opts[:key],
                reply_to: opts[:reply_to],
                correlation_id: opts[:correlation_id],
                exchange_type: type
              )
            rescue => e
              NewRelic::Agent.logger.error('Error starting message broker segment in Bunny::Exchange#publish', e)
              yield
            else
              NewRelic::Agent::Tracer.capture_segment_error(segment) do
                yield
              end
            ensure
              ::NewRelic::Agent::Transaction::Segment.finish(segment)
            end
          end
        end

        module Queue
          include Bunny

          def pop_with_tracing
            NewRelic::Agent.record_instrumentation_invocation(INSTRUMENTATION_NAME)

            bunny_error, delivery_info, message_properties, _payload = nil, nil, nil, nil
            begin
              t0 = Process.clock_gettime(Process::CLOCK_REALTIME)
              msg = yield
              delivery_info, message_properties, _payload = msg
            rescue StandardError => error
              bunny_error = error
            end

            begin
              exch_name, exch_type = if delivery_info
                [exchange_name(delivery_info.exchange),
                  exchange_type(delivery_info, channel)]
              else
                [exchange_name(NewRelic::EMPTY_STR),
                  exchange_type({}, channel)]
              end

              segment = NewRelic::Agent::Messaging.start_amqp_consume_segment(
                library: LIBRARY,
                destination_name: exch_name,
                delivery_info: (delivery_info || {}),
                message_properties: (message_properties || {headers: {}}),
                exchange_type: exch_type,
                queue_name: name,
                start_time: t0
              )
            rescue => e
              NewRelic::Agent.logger.error('Error starting message broker segment in Bunny::Queue#pop', e)
            else
              if bunny_error
                segment.notice_error(bunny_error)
                raise bunny_error
              end
            ensure
              ::NewRelic::Agent::Transaction::Segment.finish(segment)
            end

            msg
          end

          def purge_with_tracing
            NewRelic::Agent.record_instrumentation_invocation(INSTRUMENTATION_NAME)

            begin
              type = server_named? ? :temporary_queue : :queue
              segment = NewRelic::Agent::Tracer.start_message_broker_segment(
                action: :purge,
                library: LIBRARY,
                destination_type: type,
                destination_name: name
              )
            rescue => e
              NewRelic::Agent.logger.error('Error starting message broker segment in Bunny::Queue#purge', e)
              yield
            else
              NewRelic::Agent::Tracer.capture_segment_error(segment) do
                yield
              end
            ensure
              ::NewRelic::Agent::Transaction::Segment.finish(segment)
            end
          end
        end

        module Consumer
          include Bunny

          def call_with_tracing(*args)
            NewRelic::Agent.record_instrumentation_invocation(INSTRUMENTATION_NAME)

            delivery_info, message_properties, _ = args
            queue_name = queue.respond_to?(:name) ? queue.name : queue

            NewRelic::Agent::Messaging.wrap_amqp_consume_transaction(
              library: LIBRARY,
              destination_name: exchange_name(delivery_info.exchange),
              delivery_info: delivery_info,
              message_properties: message_properties,
              exchange_type: exchange_type(delivery_info, channel),
              queue_name: queue_name
            ) do
              yield
            end
          end
        end
      end
    end
  end
end
