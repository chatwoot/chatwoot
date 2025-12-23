# frozen_string_literal: true

module Datadog
  module Core
    # Base class for work tasks
    class Worker
      attr_reader \
        :task

      def initialize(&block)
        @task = block
      end

      def perform(*args)
        task&.call(*args)
      end

      protected

      attr_writer \
        :task
    end
  end
end
