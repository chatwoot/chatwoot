# frozen_string_literal: true

module Bullet
  module Notification
    class NPlusOneQuery < Base
      def initialize(callers, base_class, associations, path = nil)
        super(base_class, associations, path)

        @callers = callers
      end

      def body
        "#{klazz_associations_str}\n  Add to your query: #{associations_str}"
      end

      def title
        "USE eager loading #{@path ? "in #{@path}" : 'detected'}"
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
