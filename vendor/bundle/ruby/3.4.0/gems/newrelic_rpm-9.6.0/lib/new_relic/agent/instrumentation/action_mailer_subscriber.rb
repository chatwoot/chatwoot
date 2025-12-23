# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/instrumentation/notifications_subscriber'

module NewRelic
  module Agent
    module Instrumentation
      # NOTE: as of v7.1.0.0.alpha, deliver.action_mailer will provide
      # an empty payload hash ({}) to #start, so in this subscriber class
      # we defer params population until #finish and start the segment with
      # a temporary name that is later replaced
      class ActionMailerSubscriber < NotificationsSubscriber
        BASE_NAME = 'Ruby/ActionMailer'
        PAYLOAD_KEYS = %i[action data key mailer message_id perform_deliveries subject]
        PATTERN = /\A([^\.]+)\.action_mailer\z/
        UNKNOWN_MAILER = %r{^#{BASE_NAME}/#{UNKNOWN}/}

        METHOD_NAME_MAPPING = Hash.new do |h, k|
          if PATTERN =~ k
            h[k] = $1
          else
            h[k] = NewRelic::UNKNOWN
          end
        end

        def start(name, id, payload)
          return unless state.is_execution_traced?

          start_segment(name, id, payload)
        rescue => e
          log_notification_error(e, name, 'start')
        end

        def finish(name, id, payload)
          return unless state.is_execution_traced?

          finish_segment(id, payload)
        rescue => e
          log_notification_error(e, name, 'finish')
        end

        private

        def start_segment(name, id, payload)
          segment = Tracer.start_segment(name: metric_name(name, payload))
          push_segment(id, segment)
        end

        def finish_segment(id, payload)
          segment = pop_segment(id)
          return unless segment

          if segment.name.match?(UNKNOWN_MAILER) && payload.key?(:mailer)
            segment.name = segment.name.sub(UNKNOWN_MAILER, "#{BASE_NAME}/#{payload[:mailer]}/")
          end

          PAYLOAD_KEYS.each do |key|
            segment.params[key] = payload[key] if payload.key?(key)
          end

          notice_exception(segment, payload)
          segment.finish
        end

        def notice_exception(segment, payload)
          if exception = exception_object(payload)
            segment.notice_error(exception)
          end
        end

        def metric_name(name, payload)
          mailer = payload[:mailer] || UNKNOWN
          method = method_from_name(name)
          "#{BASE_NAME}/#{mailer}/#{method}"
        end

        def method_from_name(name)
          METHOD_NAME_MAPPING[name]
        end
      end
    end
  end
end
