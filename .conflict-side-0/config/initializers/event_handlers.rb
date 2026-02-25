Rails.application.configure do
  config.to_prepare do
    Rails.configuration.dispatcher = Dispatcher.instance
    Rails.configuration.dispatcher.load_listeners
  end
end
