# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'capistrano/framework'
require_relative 'helpers/send_deployment'

namespace :newrelic do
  include SendDeployment
  # notifies New Relic of a deployment
  desc 'Record a deployment in New Relic (newrelic.com)'
  task :notice_deployment do
    if fetch(:newrelic_role)
      on roles(fetch(:newrelic_role)) do
        send_deployment_notification_to_newrelic
      end
    else
      run_locally do
        send_deployment_notification_to_newrelic
      end
    end
  end
end
