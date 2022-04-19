class Campaigns::CampaignConversationBuilder
  pattr_initialize [:contact_inbox_id!, :campaign_display_id!, :conversation_additional_attributes, :custom_attributes]

  def perform
    @contact_inbox = ContactInbox.find(@contact_inbox_id)
    @campaign = @contact_inbox.inbox.campaigns.find_by!(display_id: campaign_display_id)

    ActiveRecord::Base.transaction do
      @contact_inbox.lock!

      # We won't send campaigns if a conversation is already present
      return if @contact_inbox.reload.conversations.present?

      @conversation = ::Conversation.create!(conversation_params)
      Messages::MessageBuilder.new(@campaign.sender, @conversation, message_params).perform
    end
    @conversation
  end

  private

  def message_params
    ActionController::Parameters.new({
                                       content: @campaign.message
                                     })
  end

  def conversation_params
    {
      account_id: @campaign.account_id,
      inbox_id: @contact_inbox.inbox_id,
      contact_id: @contact_inbox.contact_id,
      contact_inbox_id: @contact_inbox.id,
      campaign_id: @campaign.id,
      additional_attributes: conversation_additional_attributes,
      custom_attributes: custom_attributes || {}
    }
  end
end
