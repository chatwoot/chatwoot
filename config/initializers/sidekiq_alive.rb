SidekiqAlive.setup do |config|
  config.host = ENV.fetch('SIDEKIQ_ALIVE_HOST', '127.0.0.1')
  config.port = Integer(ENV.fetch('SIDEKIQ_ALIVE_PORT', 7433))
end
