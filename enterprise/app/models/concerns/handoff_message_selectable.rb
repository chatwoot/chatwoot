module Concerns::HandoffMessageSelectable
  extend ActiveSupport::Concern

  def handoff_message_for(conversation)
    default_message = config['handoff_message']
    return default_message unless account.feature_enabled?('captain_integration_v2')
    return default_message if conversation.campaign.present? || !conversation.inbox.out_of_office?

    config['handoff_message_outside_business_hours'].presence ||
      conversation.inbox.out_of_office_message.presence ||
      default_message
  end
end
