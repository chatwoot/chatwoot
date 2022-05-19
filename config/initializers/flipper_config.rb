require Rails.root.join('lib/redis/config')

Rails.application.configure do
  # Preload is disabled as we need the check only is certain routes
  config.flipper.preload = false
end
