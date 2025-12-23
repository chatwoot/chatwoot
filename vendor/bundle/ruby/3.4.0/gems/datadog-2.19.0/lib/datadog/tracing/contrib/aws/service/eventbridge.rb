# frozen_string_literal: true

require_relative './base'
require_relative '../ext'

module Datadog
  module Tracing
    module Contrib
      module Aws
        module Service
          # EventBridge tag handlers.
          class EventBridge < Base
            def add_tags(span, params)
              rule_name = params[:name] || params[:rule]
              span.set_tag(Aws::Ext::TAG_RULE_NAME, rule_name)
            end
          end
        end
      end
    end
  end
end
