# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

# The capistrano recipes in plugins are automatically
# loaded from here.  From gems, they are available from
# the lib directory.  We have to make them available from
# both locations

require File.join(File.dirname(__FILE__), '..', 'lib', 'new_relic', 'recipes')
