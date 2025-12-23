# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

DependencyDetection.defer do
  named :mongo

  depends_on do
    defined?(Mongo)
  end

  depends_on do
    require 'new_relic/agent/datastores/mongo'
    unless NewRelic::Agent::Datastores::Mongo.is_supported_version?
      NewRelic::Agent.logger.log_once(:warn, :mongo2, 'Detected unsupported Mongo 2, upgrade your Mongo Driver to 2.1 or newer for instrumentation')
    end
    NewRelic::Agent::Datastores::Mongo.is_supported_version?
  end

  executes do
    NewRelic::Agent.logger.info('Installing Mongo instrumentation')
    install_mongo_command_subscriber
  end

  def install_mongo_command_subscriber
    require 'new_relic/agent/instrumentation/mongodb_command_subscriber'
    Mongo::Monitoring::Global.subscribe(
      Mongo::Monitoring::COMMAND,
      NewRelic::Agent::Instrumentation::MongodbCommandSubscriber.new
    )
  end
end
