class Api::V1::Accounts::Contacts::CallsController < Api::V1::Accounts::BaseController
  before_action :fetch_contact

  def create
    # Find a Voice channel
    voice_inbox = Current.account.inboxes.find_by(channel_type: 'Channel::Voice')
    
    if voice_inbox.blank?
      render json: { error: 'No Voice channel found' }, status: :unprocessable_entity
      return
    end

    if @contact.phone_number.blank?
      render json: { error: 'Contact has no phone number' }, status: :unprocessable_entity
      return
    end

    begin
      # Initiate the call using the channel's implementation
      voice_inbox.channel.initiate_call(to: @contact.phone_number)

      # Create a new conversation for this call if needed
      conversation = find_or_create_conversation(voice_inbox)
      
      render json: conversation
    rescue StandardError => e
      Rails.logger.error("Error initiating call: #{e.message}")
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  private

  def fetch_contact
    @contact = Current.account.contacts.find(params[:contact_id])
  end

  def find_or_create_conversation(inbox)
    conversation = inbox.conversations.where(contact_id: @contact.id).last

    if conversation.nil? || !conversation.open?
      # Find or create a contact_inbox for this contact and inbox
      contact_inbox = ContactInbox.find_or_create_by!(
        contact_id: @contact.id,
        inbox_id: inbox.id
      )
      
      conversation = ::Conversation.create!(
        account_id: Current.account.id,
        inbox_id: inbox.id,
        contact_id: @contact.id,
        contact_inbox_id: contact_inbox.id,
        status: :open
      )

      # Add a note about the call being initiated
      Messages::MessageBuilder.new(
        user: Current.user,
        conversation: conversation,
        message_type: :activity,
        content: "Voice call initiated to #{@contact.phone_number}"
      ).perform
    end

    conversation
  end
end