# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/instrumentation/action_view_subscriber'
require 'new_relic/agent/prepend_supportability'

DependencyDetection.defer do
  @name = :action_view_notifications

  depends_on do
    defined?(Rails::VERSION::MAJOR) && Rails::VERSION::MAJOR.to_i >= 4
  end

  depends_on do
    !NewRelic::Agent.config[:disable_view_instrumentation] &&
      !NewRelic::Agent::Instrumentation::ActionViewSubscriber.subscribed?
  end

  executes do
    NewRelic::Agent.logger.info('Installing notification based Action View instrumentation')
  end

  executes do
    ActiveSupport.on_load(:action_view) do
      NewRelic::Agent::Instrumentation::ActionViewSubscriber.subscribe(/render_.+\.action_view$/)
      NewRelic::Agent::PrependSupportability.record_metrics_for(ActionView::Base, ActionView::Template, ActionView::Renderer)
    end
  end
end
