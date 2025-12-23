# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/instrumentation/notifications_subscriber'

module NewRelic
  module Agent
    module Instrumentation
      class ActiveStorageSubscriber < NotificationsSubscriber
        def add_segment_params(segment, payload)
          segment.params[:key] = payload[:key]
          segment.params[:exist] = payload[:exist] if payload.key?(:exist)
        end

        def metric_name(name, payload)
          service = payload[:service]
          method = method_from_name(name)
          "Ruby/ActiveStorage/#{service}Service/#{method}"
        end

        PATTERN = /\Aservice_([^\.]*)\.active_storage\z/

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
