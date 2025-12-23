# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/instrumentation/notifications_subscriber'
require 'new_relic/agent/instrumentation/ignore_actions'
require 'new_relic/agent/parameter_filtering'

module NewRelic
  module Agent
    module Instrumentation
      class ActionControllerOtherSubscriber < NotificationsSubscriber
        def add_segment_params(segment, payload)
          segment.params[:filter] = payload[:filter] if payload[:filter]
          segment.params[:keys] = payload[:keys] if payload[:keys]
          segment.params[:original_path] = payload[:request].original_fullpath if payload[:request]

          if payload[:context]
            segment.params[:action] = payload[:context][:action]
            segment.params[:controller] = payload[:context][:controller]
          end
        end

        def metric_name(name, payload)
          controller_name = controller_name_for_metric(payload)
          "Ruby/ActionController#{"/#{controller_name}" if controller_name}/#{name.gsub('.action_controller', '')}"
        end

        def controller_name_for_metric(payload)
          return unless payload
          # redirect_to
          return payload[:request].controller_class.controller_path if payload[:request].respond_to?(:controller_class) && payload[:request].controller_class&.respond_to?(:controller_path)

          # unpermitted_parameters
          if payload[:context]&.[](:controller) && constantized_class = ::NewRelic::LanguageSupport.constantize(payload[:context][:controller])
            constantized_class.respond_to?(:controller_path) ? constantized_class.controller_path : nil
          end
        end
      end
    end
  end
end
