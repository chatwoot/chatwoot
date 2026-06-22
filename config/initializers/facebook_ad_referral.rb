# frozen_string_literal: true

# Facebook Messenger ad referral feature.
# To remove: delete this file and lib/integrations/facebook/ad_referral/
Rails.application.config.to_prepare do
  Integrations::Facebook::MessageParser.prepend(
    Integrations::Facebook::AdReferral::MessageParserExtension
  )
  Messages::Facebook::MessageBuilder.prepend(
    Integrations::Facebook::AdReferral::MessageBuilderExtension
  )
end
