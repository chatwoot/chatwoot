class Campaigns::OneoffConversationBuilder
  pattr_initialize [:contact_inbox_id!, :campaign_display_id!, :conversation_additional_attributes, :custom_attributes, :template_params, :content]

  def perform
    @contact_inbox = ContactInbox.find(@contact_inbox_id)
    @campaign = @contact_inbox.inbox.campaigns.find_by!(display_id: campaign_display_id)
    ActiveRecord::Base.transaction do
      @contact_inbox.lock!

      conversations = @contact_inbox.reload.conversations
      @conversation = if conversations&.open&.length()&.> 0
                        conversations.open[0]
                      else
                        ::Conversation.create!(conversation_params)

                      end

      Messages::MessageBuilder.new(@campaign.sender, @conversation, message_params).perform
    end
    @conversation
  rescue StandardError => e
    Rails.logger.info(e.message)
    nil
  end

  private

  def message_params
    ActionController::Parameters.new({
                                       campaign_id: @campaign.id,
                                       template_params: {
                                         **@template_params,
                                         processed_params: @template_params[:processed_params].is_a?(Hash) ? @template_params[:processed_params] : {}
                                       },
                                       content: @content
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
      custom_attributes: custom_attributes || {},
      status: 'resolved'
    }
  end
end
