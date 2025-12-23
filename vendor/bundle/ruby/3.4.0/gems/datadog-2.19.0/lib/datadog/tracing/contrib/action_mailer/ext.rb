# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module ActionMailer
        # ActionMailer integration constants
        # @public_api Changing resource names, tag names, or environment variables creates breaking changes.
        module Ext
          ENV_ENABLED = 'DD_TRACE_ACTION_MAILER_ENABLED'
          # @!visibility private
          ENV_ANALYTICS_ENABLED = 'DD_TRACE_ACTION_MAILER_ANALYTICS_ENABLED'
          ENV_ANALYTICS_SAMPLE_RATE = 'DD_TRACE_ACTION_MAILER_ANALYTICS_SAMPLE_RATE'
          SPAN_PROCESS = 'action_mailer.process'
          SPAN_DELIVER = 'action_mailer.deliver'
          TAG_COMPONENT = 'action_mailer'
          TAG_ACTION = 'action_mailer.action'
          TAG_MAILER = 'action_mailer.mailer'
          TAG_MSG_ID = 'action_mailer.message_id'
          TAG_OPERATION_DELIVER = 'deliver'
          TAG_OPERATION_PROCESS = 'process'

          TAG_SUBJECT = 'action_mailer.subject'
          TAG_TO = 'action_mailer.to'
          TAG_FROM = 'action_mailer.from'
          TAG_BCC = 'action_mailer.bcc'
          TAG_CC = 'action_mailer.cc'
          TAG_DATE = 'action_mailer.date'
          TAG_PERFORM_DELIVERIES = 'action_mailer.perform_deliveries'
        end
      end
    end
  end
end
