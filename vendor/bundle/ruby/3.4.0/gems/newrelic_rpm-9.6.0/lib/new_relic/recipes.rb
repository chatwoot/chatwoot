# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

# When installed as a plugin, this is loaded automatically.
#
# When installed as a gem, you need to add
#  require 'new_relic/recipes'
# to deploy.rb
#
# Defines newrelic:notice_deployment, which sends information about the deploy
# to New Relic. The task will run on all app release roles. If it fails, it will
# not affect the execution of subsequent tasks or cause a rollback.
#
# @api public
#

require 'capistrano/version'

if defined?(Capistrano::VERSION) && Capistrano::VERSION.to_s.split('.').first.to_i >= 3
  require 'new_relic/recipes/capistrano3'
else
  require 'new_relic/recipes/capistrano_legacy'
end
