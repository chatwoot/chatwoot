# frozen_string_literal: true

module Aws
  module Binary

    # @api private
    class DecodeHandler < Seahorse::Client::Handler

      def call(context)
        if eventstream_member = eventstream?(context)
          attach_eventstream_listeners(context, eventstream_member)
        end
        @handler.call(context)
      end

      private

      def eventstream?(ctx)
        ctx.operation.output.shape.members.each do |_, ref|
          return ref if ref.eventstream
        end
      end

      def attach_eventstream_listeners(context, rules)

        context.http_response.on_headers(200) do
          protocol = context.config.api.metadata['protocol']
          output_handler = context[:output_event_stream_handler] || context[:event_stream_handler]
          context.http_response.body = EventStreamDecoder.new(
            protocol,
            rules,
            context.operation.output,
            context.operation.errors,
            context.http_response.body,
            output_handler)
          if input_emitter = context[:input_event_emitter]
            # #emit will be blocked until 200 success
            # see Aws::EventEmitter#emit
            input_emitter.signal_queue << "ready"
          end
        end

        context.http_response.on_success(200) do
          context.http_response.body = context.http_response.body.events
        end

        context.http_response.on_error do
          # Potential enhancement to made
          # since we don't want to track raw bytes in memory
          context.http_response.body = StringIO.new
        end

      end

    end

  end
end
