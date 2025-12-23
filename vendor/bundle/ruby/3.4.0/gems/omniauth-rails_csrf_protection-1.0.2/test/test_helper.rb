$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

# Simple Rails application template, based on Rails issue template
# https://github.com/rails/rails/blob/master/guides/bug_report_templates/action_controller_gem.rb

# Helper method to silence warnings from bundler/inline
def silence_warnings
  old_verbose, $VERBOSE = $VERBOSE, nil
  yield
ensure
  $VERBOSE = old_verbose
end

silence_warnings do
  require "bundler/inline"

  # Define dependencies required by this test app
  gemfile do
    source "https://rubygems.org"

    if ENV["RAILS_VERSION"] == "edge"
      gem "rails", git: "https://github.com/rails/rails.git", branch: "main"
    else
      gem "rails"
    end

    gem "omniauth"
    gem "omniauth-rails_csrf_protection", path: File.expand_path("..", __dir__)
  end
end

puts "Running test against Rails #{Rails.version}"

require "rack/test"
require "action_controller/railtie"
require "minitest/autorun"

# Build a test application which uses OmniAuth
class TestApp < Rails::Application
  config.root = __dir__
  config.session_store :cookie_store, key: "cookie_store_key"
  config.secret_key_base = "secret_key_base"
  config.eager_load = false
  config.hosts = []

  # This allow us to send all logs to STDOUT if we run test wth `VERBOSE=1`
  config.logger = if ENV["VERBOSE"]
                    Logger.new($stdout)
                  else
                    Logger.new("/dev/null")
                  end
  Rails.logger = config.logger
  OmniAuth.config.logger = Rails.logger

  # Setup a simple OmniAuth configuration with only developer provider
  config.middleware.use OmniAuth::Builder do
    provider :developer
  end

  # We need to call initialize! to run all railties
  initialize!

  # Define our custom routes. This needs to be called after initialize!
  routes.draw do
    get "token" => "application#token"
  end
end

# A small test controller which we use to retrive the valid authenticity token
class ApplicationController < ActionController::Base
  def token
    render plain: form_authenticity_token
  end
end
