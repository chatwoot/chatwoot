# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'yaml'
require 'new_relic/dependency_detection'
require 'new_relic/local_environment'
require 'new_relic/language_support'
require 'new_relic/helper'

require 'singleton'
require 'erb'
require 'socket'
require 'net/https'
require 'logger'
require 'new_relic/control/frameworks'
require 'new_relic/control/server_methods'
require 'new_relic/control/instrumentation'
require 'new_relic/control/class_methods'
require 'new_relic/control/instance_methods'

require 'new_relic/agent'
require 'new_relic/delayed_job_injection'

module NewRelic
  # The Control is a singleton responsible for the startup and
  # initialization sequence.  The initializer uses a LocalEnvironment to
  # detect the framework and instantiates the framework specific
  # subclass.
  #
  # The Control also implements some of the public API for the agent.
  #
  class Control
    # done in a subfile for load order purposes
    # extend ClassMethods
    # include InstanceMethods
    # include Configuration
    # include ServerMethods
    # include Instrumentation
  end
end
