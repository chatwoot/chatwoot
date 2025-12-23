# frozen_string_literal: true

require_relative '../../../metadata/ext'
require_relative '../ext'
require_relative '../event'

module Datadog
  module Tracing
    module Contrib
      module ActionMailer
        module Events
          # Defines instrumentation for deliver.action_mailer event
          module Deliver
            include ActionMailer::Event

            EVENT_NAME = 'deliver.action_mailer'

            module_function

            def event_name
              self::EVENT_NAME
            end

            def span_name
              Ext::SPAN_DELIVER
            end

            def span_type
              # deliver.action_mailer sends emails
              Tracing::Metadata::Ext::AppTypes::TYPE_WORKER
            end

            def on_start(span, event, _id, payload)
              super

              span.set_tag(Tracing::Metadata::Ext::TAG_OPERATION, Ext::TAG_OPERATION_DELIVER)
            end

            def on_finish(span, event, _id, payload)
              super

              span.resource = payload[:mailer] # Mailer is not available at `on_start`

              span.set_tag(Ext::TAG_MAILER, payload[:mailer])
              span.set_tag(Ext::TAG_MSG_ID, payload[:message_id])

              # Since email data can contain PII we disable by default
              # Some of these fields can be either strings or arrays, so we try to normalize
              # https://github.com/rails/rails/blob/18707ab17fa492eb25ad2e8f9818a320dc20b823/actionmailer/lib/action_mailer/base.rb#L742-L754
              if configuration[:email_data] == true
                span.set_tag(Ext::TAG_SUBJECT, payload[:subject].to_s) if payload[:subject]
                span.set_tag(Ext::TAG_TO, payload[:to].join(',')) if payload[:to]
                span.set_tag(Ext::TAG_FROM, payload[:from].join(',')) if payload[:from]
                span.set_tag(Ext::TAG_BCC, payload[:bcc].join(',')) if payload[:bcc]
                span.set_tag(Ext::TAG_CC, payload[:cc].join(',')) if payload[:cc]
                span.set_tag(Ext::TAG_DATE, payload[:date].to_s) if payload[:date]
                span.set_tag(Ext::TAG_PERFORM_DELIVERIES, payload[:perform_deliveries]) if payload[:perform_deliveries]
              end
            end
          end
        end
      end
    end
  end
end
