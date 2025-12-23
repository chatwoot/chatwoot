# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/transaction'

module NewRelic
  module Agent
    #
    # This module contains helper methods to facilitate instrumentation of
    # message brokers.
    #
    # @api public
    module Messaging
      extend self

      RABBITMQ_TRANSPORT_TYPE = 'RabbitMQ'

      ATTR_DESTINATION = AttributeFilter::DST_TRANSACTION_EVENTS |
        AttributeFilter::DST_TRANSACTION_TRACER |
        AttributeFilter::DST_ERROR_COLLECTOR

      # Start a MessageBroker segment configured to trace a messaging action.
      # Finishing this segment will handle timing and recording of the proper
      # metrics for New Relic's messaging features..
      #
      # @param action [Symbol] The message broker action being traced (see
      #   NewRelic::Agent::Transaction::MessageBrokerSegment::ACTIONS) for
      #   all options.
      #
      # @param library [String] The name of the library being instrumented
      #
      # @param destination_type [Symbol] Type of destination (see
      #   NewRelic::Agent::Transaction::MessageBrokerSegment::DESTINATION_TYPES)
      #   for all options.
      #
      # @param destination_name [String] Name of destination (queue or
      #   exchange name)
      #
      # @param headers [Hash] Metadata about the message and opaque
      #   application-level data (optional)
      #
      # @param parameters [Hash] A hash of parameters to be attached to this
      #   segment (optional)
      #
      # @param start_time [Time] An instance of Time class denoting the start
      #   time of the segment. Value is set by AbstractSegment#start if not
      #   given. (optional)
      #
      # @return [NewRelic::Agent::Transaction::MessageBrokerSegment]
      #
      # @api public
      #
      def start_message_broker_segment(action: nil,
        library: nil,
        destination_type: nil,
        destination_name: nil,
        headers: nil,
        parameters: nil,
        start_time: nil)

        Tracer.start_message_broker_segment(
          action: action,
          library: library,
          destination_type: destination_type,
          destination_name: destination_name,
          headers: headers,
          parameters: parameters,
          start_time: start_time
        )
      end

      # Wrap a MessageBroker transaction trace around a messaging handling block.
      # This API is intended to be used in library instrumentation when a "push"-
      # style callback is invoked to handle an incoming message.
      #
      # @param library [String] The name of the library being instrumented
      #
      # @param destination_type [Symbol] Type of destination (see
      #   +NewRelic::Agent::Transaction::MessageBrokerSegment::DESTINATION_TYPES+)
      #   for all options.
      #
      # @param destination_name [String] Name of destination (queue or
      #   exchange name)
      #
      # @param headers [Hash] Metadata about the message and opaque
      #   application-level data (optional)
      #
      # @param routing_key [String] Value used by AMQP message brokers to route
      #   messages to queues
      #
      # @param queue_name [String] Name of AMQP queue that received the
      #   message (optional)
      #
      # @param exchange_type [Symbol] Type of last AMQP exchange to deliver the
      #   message (optional)
      #
      # @param reply_to [String] Routing key to be used to send AMQP-based RPC
      #   response messages (optional)
      #
      # @param correlation_id [String] Application-level value used to correlate
      #   AMQP-based RPC response messages to request messages (optional)
      #
      # @param &block [Proc] The block should handle calling the original subscribed
      #   callback function
      #
      # @return return value of given block, which will be the same as the
      #   return value of an un-instrumented subscribed callback
      #
      # @api public
      #
      def wrap_message_broker_consume_transaction(library:,
        destination_type:,
        destination_name:,
        headers: nil,
        routing_key: nil,
        queue_name: nil,
        exchange_type: nil,
        reply_to: nil,
        correlation_id: nil)

        state = Tracer.state
        return yield if state.current_transaction

        txn = nil

        begin
          txn_name = transaction_name(library, destination_type, destination_name)

          txn = Tracer.start_transaction(name: txn_name, category: :message)

          if headers
            txn.distributed_tracer.consume_message_headers(headers, state, RABBITMQ_TRANSPORT_TYPE)
            CrossAppTracing.reject_messaging_cat_headers(headers).each do |k, v|
              txn.add_agent_attribute(:"message.headers.#{k}", v, AttributeFilter::DST_NONE) unless v.nil?
            end
          end

          txn.add_agent_attribute(:'message.routingKey', routing_key, ATTR_DESTINATION) if routing_key
          txn.add_agent_attribute(:'message.exchangeType', exchange_type, AttributeFilter::DST_NONE) if exchange_type
          txn.add_agent_attribute(:'message.correlationId', correlation_id, AttributeFilter::DST_NONE) if correlation_id
          txn.add_agent_attribute(:'message.queueName', queue_name, ATTR_DESTINATION) if queue_name
          txn.add_agent_attribute(:'message.replyTo', reply_to, AttributeFilter::DST_NONE) if reply_to
        rescue => e
          NewRelic::Agent.logger.error('Error starting Message Broker consume transaction', e)
        end

        yield
      ensure
        begin
          # the following line needs else branch coverage
          txn.finish if txn # rubocop:disable Style/SafeNavigation
        rescue => e
          NewRelic::Agent.logger.error('Error stopping Message Broker consume transaction', e)
        end
      end

      # Start a MessageBroker segment configured to trace an AMQP publish.
      # Finishing this segment will handle timing and recording of the proper
      # metrics for New Relic's messaging features. This method is a convenience
      # wrapper around NewRelic::Agent::Tracer.start_message_broker_segment.
      #
      # @param library [String] The name of the library being instrumented
      #
      # @param destination_name [String] Name of destination (exchange name)
      #
      # @param headers [Hash] The message headers
      #
      # @param routing_key [String] The routing key used for the message (optional)
      #
      # @param reply_to [String] A routing key for use in RPC-models for the
      #   receiver to publish a response to (optional)
      #
      # @param correlation_id [String] An application-generated value to link up
      #   request and responses in RPC-models (optional)
      #
      # @param exchange_type [String] Type of exchange which determines how
      #   message are routed (optional)
      #
      # @return [NewRelic::Agent::Transaction::MessageBrokerSegment]
      #
      # @api public
      #
      def start_amqp_publish_segment(library:,
        destination_name:,
        headers: nil,
        routing_key: nil,
        reply_to: nil,
        correlation_id: nil,
        exchange_type: nil)

        raise ArgumentError, 'missing required argument: headers' if headers.nil? && CrossAppTracing.cross_app_enabled?

        # The following line needs else branch coverage
        original_headers = headers.nil? ? nil : headers.dup # rubocop:disable Style/SafeNavigation

        segment = Tracer.start_message_broker_segment(
          action: :produce,
          library: library,
          destination_type: :exchange,
          destination_name: destination_name,
          headers: headers
        )

        if segment_parameters_enabled?
          segment.params[:headers] = original_headers if original_headers && !original_headers.empty?
          segment.params[:routing_key] = routing_key if routing_key
          segment.params[:reply_to] = reply_to if reply_to
          segment.params[:correlation_id] = correlation_id if correlation_id
          segment.params[:exchange_type] = exchange_type if exchange_type
        end

        segment
      end

      # Start a MessageBroker segment configured to trace an AMQP consume.
      # Finishing this segment will handle timing and recording of the proper
      # metrics for New Relic's messaging features. This method is a convenience
      # wrapper around NewRelic::Agent::Tracer.start_message_broker_segment.
      #
      # @param library [String] The name of the library being instrumented
      #
      # @param destination_name [String] Name of destination (exchange name)
      #
      # @param delivery_info [Hash] Metadata about how the message was delivered
      #
      # @param message_properties [Hash] AMQP-specific metadata about the message
      #   including headers and opaque application-level data
      #
      # @param exchange_type [String] Type of exchange which determines how
      #   messages are routed (optional)
      #
      # @param queue_name [String] The name of the queue the message was
      #   consumed from (optional)
      #
      # @param start_time [Time] An instance of Time class denoting the start
      #   time of the segment. Value is set by AbstractSegment#start if not
      #   given. (optional)
      #
      # @return [NewRelic::Agent::Transaction::MessageBrokerSegment]
      #
      # @api public
      #
      def start_amqp_consume_segment(library:,
        destination_name:,
        delivery_info:,
        message_properties:,
        exchange_type: nil,
        queue_name: nil,
        start_time: nil)

        segment = Tracer.start_message_broker_segment(
          action: :consume,
          library: library,
          destination_name: destination_name,
          destination_type: :exchange,
          headers: message_properties[:headers],
          start_time: start_time
        )

        if segment_parameters_enabled?
          if message_properties[:headers] && !message_properties[:headers].empty?
            non_cat_headers = CrossAppTracing.reject_messaging_cat_headers(message_properties[:headers])
            non_synth_headers = SyntheticsMonitor.reject_messaging_synthetics_header(non_cat_headers)
            segment.params[:headers] = non_synth_headers unless non_synth_headers.empty?
          end

          segment.params[:routing_key] = delivery_info[:routing_key] if delivery_info[:routing_key]
          segment.params[:reply_to] = message_properties[:reply_to] if message_properties[:reply_to]
          segment.params[:queue_name] = queue_name if queue_name
          segment.params[:exchange_type] = exchange_type if exchange_type
          segment.params[:exchange_name] = delivery_info[:exchange_name] if delivery_info[:exchange_name]
          segment.params[:correlation_id] = message_properties[:correlation_id] if message_properties[:correlation_id]
        end

        segment
      end

      # Wrap a MessageBroker transaction trace around a AMQP messaging handling block.
      # This API is intended to be used in AMQP-specific library instrumentation when a
      # "push"-style callback is invoked to handle an incoming message.
      #
      # @param library [String] The name of the library being instrumented
      #
      # @param destination_name [String] Name of destination (queue or
      #   exchange name)
      #
      # @param message_properties [Hash] Metadata about the message and opaque
      #   application-level data (optional)
      #
      # @param exchange_type [Symbol] Type of AMQP exchange the message was received
      #   from (see NewRelic::Agent::Transaction::MessageBrokerSegment::DESTINATION_TYPES)
      #
      # @param queue_name [String] name of the AMQP queue on which the message was
      #   received
      #
      # @param &block [Proc] The block should handle calling the original subscribed
      #   callback function
      #
      # @return return value of given block, which will be the same as the
      #   return value of an un-instrumented subscribed callback
      #
      # @api public
      #
      def wrap_amqp_consume_transaction(library: nil,
        destination_name: nil,
        delivery_info: nil,
        message_properties: nil,
        exchange_type: nil,
        queue_name: nil,
        &block)

        wrap_message_broker_consume_transaction(library: library,
          destination_type: :exchange,
          destination_name: Instrumentation::Bunny.exchange_name(destination_name),
          routing_key: delivery_info[:routing_key],
          reply_to: message_properties[:reply_to],
          queue_name: queue_name,
          exchange_type: exchange_type,
          headers: message_properties[:headers],
          correlation_id: message_properties[:correlation_id], &block)
      end

      private

      def segment_parameters_enabled?
        NewRelic::Agent.config[:'message_tracer.segment_parameters.enabled']
      end

      def transaction_name(library, destination_type, destination_name)
        transaction_name = Transaction::MESSAGE_PREFIX + library
        transaction_name << NewRelic::SLASH
        transaction_name << Transaction::MessageBrokerSegment::TYPES[destination_type]
        transaction_name << NewRelic::SLASH

        case destination_type
        when :queue
          transaction_name << Transaction::MessageBrokerSegment::NAMED
          transaction_name << destination_name

        when :topic
          transaction_name << Transaction::MessageBrokerSegment::NAMED
          transaction_name << destination_name

        when :temporary_queue, :temporary_topic
          transaction_name << Transaction::MessageBrokerSegment::TEMP

        when :exchange
          transaction_name << Transaction::MessageBrokerSegment::NAMED
          transaction_name << destination_name

        end

        transaction_name
      end
    end
  end
end
