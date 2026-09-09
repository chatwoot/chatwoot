Rails.application.config.to_prepare do
  Api::V1::Accounts::ContactsController.include TelegramContactMerge
end
