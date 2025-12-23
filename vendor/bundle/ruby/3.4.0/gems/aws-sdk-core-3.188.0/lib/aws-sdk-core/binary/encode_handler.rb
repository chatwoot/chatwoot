# frozen_string_literal: true

module Aws
  module Binary

    # @api private
    class EncodeHandler < Seahorse::Client::Handler

      def call(context)
        if eventstream_member = eventstream_input?(context)
          input_es_handler = context[:input_event_stream_handler]
          input_es_handler.event_emitter.encoder = EventStreamEncoder.new(
            context.config.api.metadata['protocol'],
            eventstream_member,
            context.operation.input,
            signer_for(context)
          )
          context[:input_event_emitter] = input_es_handler.event_emitter
        end
        @handler.call(context)
      end

      private

      def signer_for(context)
        # New endpoint/signing logic, use the auth scheme to make a signer
        if context[:auth_scheme]
          Aws::Plugins::Sign.signer_for(context[:auth_scheme], context.config)
        else
          # Previous implementation always assumed sigv4_signer from config.
          # Relies only on sigv4 signing (and plugin) for event stream services
          context.config.sigv4_signer
        end
      end

      def eventstream_input?(ctx)
        ctx.operation.input.shape.members.each do |_, ref|
          return ref if ref.eventstream
        end
      end

    end

  end
end
