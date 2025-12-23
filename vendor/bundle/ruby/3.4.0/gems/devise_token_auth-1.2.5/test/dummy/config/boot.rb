# frozen_string_literal: true

unless defined?(DEVISE_TOKEN_AUTH_ORM)
  DEVISE_TOKEN_AUTH_ORM = (ENV["DEVISE_TOKEN_AUTH_ORM"] || :active_record).to_sym
end

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../../Gemfile', __dir__)

require 'bundler/setup' if File.exist?(ENV['BUNDLE_GEMFILE'])
$LOAD_PATH.unshift File.expand_path('../../../lib', __dir__)
