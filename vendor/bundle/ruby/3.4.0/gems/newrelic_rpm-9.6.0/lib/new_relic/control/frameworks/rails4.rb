# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/control/frameworks/rails3'

module NewRelic
  class Control
    module Frameworks
      class Rails4 < NewRelic::Control::Frameworks::Rails3
        def rails_gem_list
          Bundler.rubygems.all_specs.map do |gem|
            "#{gem.name} (#{gem.version})"
          end
        end

        def append_plugin_list
          # Rails 4 does not allow plugins
        end
      end
    end
  end
end
