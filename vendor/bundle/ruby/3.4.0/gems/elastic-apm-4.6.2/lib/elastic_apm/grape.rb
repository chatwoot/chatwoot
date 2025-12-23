# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

# frozen_string_literal: true

require 'elastic_apm/subscriber'
require 'elastic_apm/normalizers/grape'

module ElasticAPM
  # Module for starting the ElasticAPM agent and hooking into Grape.
  module Grape
    extend self
    # Start the ElasticAPM agent and hook into Grape.
    #
    # @param app [Grape::API] A Grape app.
    # @param config [Config, Hash] An instance of Config or a Hash config.
    # @return [true, nil] true if the agent was started, nil otherwise.
    def start(app, config = {})
      config = Config.new(config) unless config.is_a?(Config)
      configure_app(app, config)

      ElasticAPM.start(config).tap do |agent|
        attach_subscriber(agent)
      end

      ElasticAPM.running?
    rescue StandardError => e
      config.logger.error format('Failed to start: %s', e.message)
      config.logger.debug "Backtrace:\n" + e.backtrace.join("\n")
    end

    private

    def configure_app(app, config)
      config.service_name ||= app.name
      config.framework_name ||= 'Grape'
      config.framework_version ||= ::Grape::VERSION
      config.logger ||= app.logger
      config.__root_path ||= Dir.pwd
    end

    def attach_subscriber(agent)
      return unless agent

      agent.instrumenter.subscriber = ElasticAPM::Subscriber.new(agent)
    end
  end
end
