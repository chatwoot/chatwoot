# frozen_string_literal: true

module Bullet
  module Notification
    class UnusedEagerLoading < Base
      def initialize(callers, base_class, associations, path = nil)
        super(base_class, associations, path)

        @callers = callers
      end

      def body
        "#{klazz_associations_str}\n  Remove from your query: #{associations_str}"
      end

      def title
        "AVOID eager loading #{@path ? "in #{@path}" : 'detected'}"
      end

      def notification_data
        super.merge(backtrace: [])
      end

      protected

      def call_stack_messages
        (['Call stack'] + @callers).join("\n  ")
      end
    end
  end
end
