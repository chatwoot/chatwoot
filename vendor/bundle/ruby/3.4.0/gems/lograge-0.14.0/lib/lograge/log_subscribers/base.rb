# frozen_string_literal: true

require 'json'
require 'action_pack'
require 'active_support'
require 'active_support/core_ext/class/attribute'
require 'active_support/log_subscriber'
require 'request_store'

module Lograge
  module LogSubscribers
    class Base < ActiveSupport::LogSubscriber
      def logger
        Lograge.logger.presence || super
      end

      private

      def process_main_event(event)
        return if Lograge.ignore?(event)

        payload = event.payload
        data = extract_request(event, payload)
        data = before_format(data, payload)
        formatted_message = Lograge.formatter.call(data)
        logger.send(Lograge.log_level, formatted_message)
      end

      def extract_request(event, payload)
        data = initial_data(payload)
        data.merge!(extract_status(payload))
        data.merge!(extract_allocations(event))
        data.merge!(extract_runtimes(event, payload))
        data.merge!(extract_location)
        data.merge!(extract_unpermitted_params)
        data.merge!(custom_options(event))
      end

      %i[initial_data extract_status extract_runtimes
         extract_location extract_unpermitted_params].each do |method_name|
        define_method(method_name) { |*_arg| {} }
      end

      def extract_status(payload)
        if (status = payload[:status])
          { status: status.to_i }
        elsif (error = payload[:exception])
          exception, message = error
          { status: get_error_status_code(exception), error: "#{exception}: #{message}" }
        else
          { status: default_status }
        end
      end

      def default_status
        0
      end

      def get_error_status_code(exception_class_name)
        ActionDispatch::ExceptionWrapper.status_code_for_exception(exception_class_name)
      end

      def extract_allocations(event)
        if (allocations = (event.respond_to?(:allocations) && event.allocations))
          { allocations: allocations }
        else
          {}
        end
      end

      def custom_options(event)
        options = Lograge.custom_options(event) || {}
        options.merge event.payload[:custom_payload] || {}
      end

      def before_format(data, payload)
        Lograge.before_format(data, payload)
      end
    end
  end
end
