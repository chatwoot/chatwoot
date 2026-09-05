Rails.application.config.to_prepare do
  # Monkey-patch Message to mirror operator replies between linked conversations.
  Message.include(MessageWidgetProxy) if defined?(Message) && defined?(MessageWidgetProxy)
  Message.include(MessageTelegramProxy) if defined?(Message) && defined?(MessageTelegramProxy)
end
