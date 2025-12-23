# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/control/frameworks/rails'

module NewRelic
  class Control
    module Frameworks
      # Control subclass instantiated when Rails is detected.  Contains
      # Rails 3.0+  specific configuration, instrumentation, environment values,
      # etc. Many methods are inherited from the
      # NewRelic::Control::Frameworks::Rails class, where the two do
      # not differ
      class Rails3 < NewRelic::Control::Frameworks::Rails
        def env
          @env ||= (ENV['NEW_RELIC_ENV'] || ::Rails.env.to_s)
        end

        def rails_root
          ::Rails.root.to_s
        end

        def vendor_root
          @vendor_root ||= File.join(root, 'vendor', 'rails')
        end

        def version
          @rails_version ||= Gem::Version.new(::Rails::VERSION::STRING)
        end

        protected

        def install_shim
          super
          ActiveSupport.on_load(:action_controller) do
            include NewRelic::Agent::Instrumentation::ControllerInstrumentation::Shim
          end
        end
      end
    end
  end
end
