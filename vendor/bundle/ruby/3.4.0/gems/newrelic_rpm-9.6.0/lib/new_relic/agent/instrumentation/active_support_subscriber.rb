# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/instrumentation/notifications_subscriber'

module NewRelic
  module Agent
    module Instrumentation
      class ActiveSupportSubscriber < NotificationsSubscriber
        def add_segment_params(segment, payload)
          segment.params[:key] = payload[:key]
          segment.params[:store] = payload[:store]
          segment.params[:hit] = payload[:hit] if payload.key?(:hit)
          segment.params[:super_operation] = payload[:super_operation] if payload.key?(:super_operation)
          segment
        end

        def metric_name(name, payload)
          store = payload[:store]
          method = method_from_name(name)
          "Ruby/ActiveSupport#{"/#{store}" if store}/#{method}"
        end

        PATTERN = /\Acache_([^\.]*)\.active_support\z/

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
