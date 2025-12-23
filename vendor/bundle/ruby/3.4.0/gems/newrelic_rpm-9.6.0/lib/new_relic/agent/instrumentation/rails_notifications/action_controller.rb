# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/instrumentation/action_controller_subscriber'
require 'new_relic/agent/instrumentation/action_controller_other_subscriber'
require 'new_relic/agent/prepend_supportability'

DependencyDetection.defer do
  @name = :action_controller_notifications

  depends_on do
    defined?(Rails::VERSION::MAJOR) && Rails::VERSION::MAJOR.to_i >= 4
  end

  depends_on do
    !NewRelic::Agent.config[:disable_action_controller] &&
      defined?(ActionController) && (defined?(ActionController::Base) || defined?(ActionController::API))
  end

  executes do
    NewRelic::Agent.logger.info('Installing notifications based Action Controller instrumentation')
  end

  executes do
    ActiveSupport.on_load(:action_controller) do
      include NewRelic::Agent::Instrumentation::ControllerInstrumentation

      NewRelic::Agent::PrependSupportability.record_metrics_for(self)
    end

    NewRelic::Agent::Instrumentation::ActionControllerSubscriber \
      .subscribe(/^process_action.action_controller$/)

    subs = %w[send_file
      send_data
      send_stream
      redirect_to
      halted_callback
      unpermitted_parameters]

    # have to double escape period because its going from string -> regex
    NewRelic::Agent::Instrumentation::ActionControllerOtherSubscriber \
      .subscribe(Regexp.new("^(#{subs.join('|')})\\.action_controller$"))
  end
end
