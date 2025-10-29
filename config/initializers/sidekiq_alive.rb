# config/initializers/sidekiq_alive.rb
require 'sidekiq_alive'

SidekiqAlive.setup do |config|
  config.port = 7433
end

SidekiqAlive.start
