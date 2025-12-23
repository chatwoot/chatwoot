# frozen_string_literal: true

# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/version-3/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE

module Aws::S3
  module EventStreams
    class SelectObjectContentEventStream

      def initialize
        @event_emitter = Aws::EventEmitter.new
      end

      def on_records_event(&block)
        @event_emitter.on(:records, block) if block_given?
      end

      def on_stats_event(&block)
        @event_emitter.on(:stats, block) if block_given?
      end

      def on_progress_event(&block)
        @event_emitter.on(:progress, block) if block_given?
      end

      def on_cont_event(&block)
        @event_emitter.on(:cont, block) if block_given?
      end

      def on_end_event(&block)
        @event_emitter.on(:end, block) if block_given?
      end

      def on_error_event(&block)
        @event_emitter.on(:error, block) if block_given?
      end

      def on_initial_response_event(&block)
        @event_emitter.on(:initial_response, block) if block_given?
      end

      def on_unknown_event(&block)
        @event_emitter.on(:unknown_event, block) if block_given?
      end

      def on_event(&block)
        on_records_event(&block)
        on_stats_event(&block)
        on_progress_event(&block)
        on_cont_event(&block)
        on_end_event(&block)
        on_error_event(&block)
        on_initial_response_event(&block)
        on_unknown_event(&block)
      end

      # @api private
      # @return Aws::EventEmitter
      attr_reader :event_emitter

    end

  end
end

