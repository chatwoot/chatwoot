Rails.application.config.to_prepare do
  if defined?(Api::V1::Accounts::ConversationsController) &&
     defined?(Api::V1::Accounts::ConversationsControllerProxy)
    Api::V1::Accounts::ConversationsController.prepend(
      Api::V1::Accounts::ConversationsControllerProxy
    )
  end
end
