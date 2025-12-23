# frozen_string_literal: true

require_relative '../../../metadata/ext'
require_relative '../ext'
require_relative '../event'

module Datadog
  module Tracing
    module Contrib
      module ActionMailer
        module Events
          # Defines instrumentation for process.action_mailer event
          module Process
            include ActionMailer::Event

            EVENT_NAME = 'process.action_mailer'

            module_function

            def event_name
              self::EVENT_NAME
            end

            def span_name
              Ext::SPAN_PROCESS
            end

            def span_type
              # process.action_mailer processes email and renders partial templates
              Tracing::Metadata::Ext::HTTP::TYPE_TEMPLATE
            end

            def on_start(span, event, _id, payload)
              super

              span.resource = payload[:mailer] # Mailer is not available at `on_start`

              span.set_tag(Ext::TAG_ACTION, payload[:action])
              span.set_tag(Ext::TAG_MAILER, payload[:mailer])

              span.set_tag(Tracing::Metadata::Ext::TAG_OPERATION, Ext::TAG_OPERATION_PROCESS)
            end
          end
        end
      end
    end
  end
end
