# frozen_string_literal: true

module Stripe
  class Instrumentation
    # Event emitted on `request_begin` callback.
    class RequestBeginEvent
      attr_reader :method, :path

      # Arbitrary user-provided data in the form of a Ruby hash that's passed
      # from subscribers on `request_begin` to subscribers on `request_end`.
      # `request_begin` subscribers can set keys which will then be available
      # in `request_end`.
      #
      # Note that all subscribers of `request_begin` share the same object, so
      # they must be careful to set unique keys so as to not conflict with data
      # set by other subscribers.
      attr_reader :user_data

      def initialize(method:, path:, user_data:)
        @method = method
        @path = path
        @user_data = user_data
        freeze
      end
    end

    # Event emitted on `request_end` callback.
    class RequestEndEvent
      attr_reader :duration, :http_status, :method, :num_retries, :path, :request_id, :response_header, :response_body,
                  :request_header, :request_body

      # Arbitrary user-provided data in the form of a Ruby hash that's passed
      # from subscribers on `request_begin` to subscribers on `request_end`.
      # `request_begin` subscribers can set keys which will then be available
      # in `request_end`.
      attr_reader :user_data

      def initialize(request_context:, response_context:,
                     num_retries:, user_data: nil)
        @duration = request_context.duration
        @http_status = response_context.http_status
        @method = request_context.method
        @num_retries = num_retries
        @path = request_context.path
        @request_id = request_context.request_id
        @user_data = user_data
        @response_header = response_context.header
        @response_body = response_context.body
        @request_header = request_context.header
        @request_body = request_context.body
        freeze
      end
    end

    class RequestContext
      attr_reader :duration, :method, :path, :request_id, :body, :header

      def initialize(duration:, context:, header:)
        @duration = duration
        @method = context.method
        @path = context.path
        @request_id = context.request_id
        @body = context.body
        @header = header
      end
    end

    class ResponseContext
      attr_reader :http_status, :body, :header

      def initialize(http_status:, response:)
        @http_status = http_status
        @header = response ? response.to_hash : nil
        @body = response ? response.body : nil
      end
    end

    # This class was renamed for consistency. This alias is here for backwards
    # compatibility.
    RequestEvent = RequestEndEvent

    # Returns true if there are a non-zero number of subscribers on the given
    # topic, and false otherwise.
    def self.any_subscribers?(topic)
      !subscribers[topic].empty?
    end

    def self.subscribe(topic, name = rand, &block)
      subscribers[topic][name] = block
      name
    end

    def self.unsubscribe(topic, name)
      subscribers[topic].delete(name)
    end

    def self.notify(topic, event)
      subscribers[topic].each_value { |subscriber| subscriber.call(event) }
    end

    def self.subscribers
      @subscribers ||= Hash.new { |hash, key| hash[key] = {} }
    end
    private_class_method :subscribers
  end
end
