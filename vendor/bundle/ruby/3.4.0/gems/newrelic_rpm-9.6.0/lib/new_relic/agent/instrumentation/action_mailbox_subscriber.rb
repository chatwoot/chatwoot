# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/instrumentation/notifications_subscriber'

module NewRelic
  module Agent
    module Instrumentation
      class ActionMailboxSubscriber < NotificationsSubscriber
        def metric_name(name, payload)
          mailbox = payload[:mailbox].class.name
          method = method_from_name(name)
          "Ruby/ActionMailbox/#{mailbox}/#{method}"
        end

        PATTERN = /\A([^\.]*)\.action_mailbox\z/

        METHOD_NAME_MAPPING = Hash.new do |h, k|
          if PATTERN =~ k
            h[k] = $1
          else
            h[k] = NewRelic::UNKNOWN
          end
        end

        def method_from_name(name)
          METHOD_NAME_MAPPING[name]
        end
      end
    end
  end
end
