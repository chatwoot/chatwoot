# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  class Control
    # class-level methods for lazy creation of NewRelic::Control and
    # NewRelic::LocalEnvironment instances.
    module ClassMethods
      # Access the Control singleton, lazy initialized.  Default will instantiate a new
      # instance or pass false to defer
      def instance(create = true)
        @instance ||= create && new_instance
      end

      # clear out memoized Control and LocalEnv instances
      def reset
        @instance = nil
        @local_env = nil
      end

      # Access the LocalEnvironment singleton, lazy initialized
      def local_env
        @local_env ||= NewRelic::LocalEnvironment.new
      end

      # Create the concrete class for environment specific behavior
      def new_instance
        if Agent.config[:framework] == :test
          load_test_framework
        else
          load_framework_class(Agent.config[:framework]).new(local_env)
        end
      end

      # nb this does not 'load test' the framework, it loads the 'test framework'
      def load_test_framework
        config = File.expand_path(File.join('..', '..', '..', '..', 'test', 'config', 'newrelic.yml'), __FILE__)
        require 'config/test_control'
        NewRelic::Control::Frameworks::Test.new(local_env, config)
      end

      # Loads the specified framework class from the
      # NewRelic::Control::Frameworks module
      def load_framework_class(framework)
        begin
          require "new_relic/control/frameworks/#{framework}"
        rescue LoadError
          # maybe it is already loaded by some external system
          # i.e. rpm_contrib or user extensions?
        end
        NewRelic::Control::Frameworks.const_get(NewRelic::LanguageSupport.camelize(framework.to_s))
      end

      # The root directory for the plugin or gem
      def newrelic_root
        File.expand_path(File.join('..', '..', '..', '..'), __FILE__)
      end
    end
    extend ClassMethods
  end
end
