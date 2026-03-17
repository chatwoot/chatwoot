Rails.application.config.to_prepare do
  # Monkey-patch the widget conversations controller so that incoming
  # messages from the web widget can be mirrored into another conversation
  # without changing the widget token or frontend behavior.
  if defined?(Api::V1::Widget::ConversationsController) &&
     defined?(Api::V1::Widget::ConversationsControllerProxy)
    Api::V1::Widget::ConversationsController.prepend(
      Api::V1::Widget::ConversationsControllerProxy
    )
  end
end
