module Sentry
  module Rails
    module Tracing
      START_TIMESTAMP_NAME = :sentry_start_timestamp

      def self.register_subscribers(subscribers)
        @subscribers = subscribers
      end

      def self.subscribers
        @subscribers
      end

      def self.subscribed_tracing_events
        @subscribed_tracing_events ||= []
      end

      def self.subscribe_tracing_events
        # need to avoid duplicated subscription
        return if @subscribed

        subscribers.each do |subscriber|
          subscriber.subscribe!
          @subscribed_tracing_events ||= []
          @subscribed_tracing_events += subscriber::EVENT_NAMES
        end

        @subscribed = true
      end

      def self.unsubscribe_tracing_events
        return unless @subscribed

        subscribers.each(&:unsubscribe!)
        subscribed_tracing_events.clear

        @subscribed = false
      end

      # this is necessary because instrumentation events don't record absolute start/finish time
      # so we need to retrieve the correct time this way
      def self.patch_active_support_notifications
        unless ::ActiveSupport::Notifications::Instrumenter.ancestors.include?(SentryNotificationExtension)
          ::ActiveSupport::Notifications::Instrumenter.send(:prepend, SentryNotificationExtension)
        end

        SentryNotificationExtension.module_eval do
          def instrument(name, payload = {}, &block)
            # only inject timestamp to the events the SDK subscribes to
            if Tracing.subscribed_tracing_events.include?(name)
              payload[START_TIMESTAMP_NAME] = Time.now.utc.to_f if name[0] != "!" && payload.is_a?(Hash)
            end

            super(name, payload, &block)
          end
        end
      end

      def self.remove_active_support_notifications_patch
        if ::ActiveSupport::Notifications::Instrumenter.ancestors.include?(SentryNotificationExtension)
          SentryNotificationExtension.module_eval do
            def instrument(name, payload = {}, &block)
              super
            end
          end
        end
      end

      def self.get_current_transaction
        Sentry.get_current_scope.get_transaction if Sentry.initialized?
      end

      # it's just a container for the extended method
      module SentryNotificationExtension
      end
    end
  end
end
