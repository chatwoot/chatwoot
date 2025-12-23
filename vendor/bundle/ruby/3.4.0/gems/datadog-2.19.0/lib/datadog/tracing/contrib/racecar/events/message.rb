# frozen_string_literal: true

require_relative '../ext'
require_relative '../event'

module Datadog
  module Tracing
    module Contrib
      module Racecar
        module Events
          # Defines instrumentation for process_message.racecar event
          module Message
            include Racecar::Event

            EVENT_NAME = 'process_message.racecar'

            module_function

            def event_name
              self::EVENT_NAME
            end

            def span_name
              Ext::SPAN_MESSAGE
            end

            def span_options
              super.merge(
                tags: { Tracing::Metadata::Ext::TAG_OPERATION => Ext::TAG_OPERATION_MESSAGE,
                        Tracing::Metadata::Ext::TAG_KIND => Tracing::Metadata::Ext::SpanKind::TAG_CONSUMER }
              )
            end
          end
        end
      end
    end
  end
end
