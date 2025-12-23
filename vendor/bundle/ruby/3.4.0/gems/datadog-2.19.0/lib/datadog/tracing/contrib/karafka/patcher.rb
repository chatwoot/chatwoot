# frozen_string_literal: true

require_relative '../patcher'
require_relative 'ext'
require_relative 'distributed/propagation'

module Datadog
  module Tracing
    module Contrib
      module Karafka
        # Patch to add tracing to Karafka::Messages::Messages
        module MessagesPatch
          def configuration
            Datadog.configuration.tracing[:karafka]
          end

          def propagation
            @propagation ||= Contrib::Karafka::Distributed::Propagation.new
          end

          # `each` is the most popular access point to Karafka messages,
          # but not the only one
          #  Other access patterns do not have a straightforward tracing avenue
          # (e.g. `my_batch_operation messages.payloads`)
          # @see https://github.com/karafka/karafka/blob/b06d1f7c17818e1605f80c2bb573454a33376b40/README.md?plain=1#L29-L35
          def each(&block)
            @messages_array.each do |message|
              if configuration[:distributed_tracing]
                headers = if message.metadata.respond_to?(:raw_headers)
                            message.metadata.raw_headers
                          else
                            message.metadata.headers
                          end
                trace_digest = Karafka.extract(headers)
                Datadog::Tracing.continue_trace!(trace_digest) if trace_digest
              end

              Tracing.trace(Ext::SPAN_MESSAGE_CONSUME) do |span|
                span.set_tag(Ext::TAG_OFFSET, message.metadata.offset)
                span.set_tag(Contrib::Ext::Messaging::TAG_DESTINATION, message.topic)
                span.set_tag(Contrib::Ext::Messaging::TAG_SYSTEM, Ext::TAG_SYSTEM)

                span.resource = message.topic

                yield message
              end
            end
          end
        end

        # Patcher enables patching of 'karafka' module.
        module Patcher
          include Contrib::Patcher

          module_function

          def target_version
            Integration.version
          end

          def patch
            require_relative 'monitor'

            ::Karafka::Instrumentation::Monitor.prepend(Monitor)
            ::Karafka::Messages::Messages.prepend(MessagesPatch)
          end
        end
      end
    end
  end
end
