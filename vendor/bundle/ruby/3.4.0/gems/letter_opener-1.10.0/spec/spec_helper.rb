require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

require "mail"

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
end
