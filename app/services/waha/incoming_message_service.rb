class Waha::IncomingMessageService
  pattr_initialize [:params!]

  def perform
    return if waha_channel.blank?

    begin
      set_contact
      set_conversation
      create_message
    rescue StandardError => e
      Rails.logger.error "WAHA IncomingMessageService error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
  end

  private

  def waha_channel
    @waha_channel ||= Channel::WhatsappUnofficial.find_by(phone_number: params[:receiver])
  end

  def inbox
    @inbox ||= waha_channel.inbox
  end

  def set_contact
    contact_inbox = ContactInboxWithContactBuilder.new(
      source_id: params[:sender],
      inbox: inbox,
      contact_attributes: { 
        name: params[:sender_name], 
        phone_number: params[:sender] 
      }
    ).perform

    @contact_inbox = contact_inbox
    @contact = contact_inbox.contact
  end

  def set_conversation
    @conversation = @contact.conversations.where(inbox: inbox).last
    
    if @conversation.blank? || @conversation.resolved?
      @conversation = Conversation.create!(
        account_id: @contact.account_id,
        inbox: inbox,
        contact: @contact,
        contact_inbox: @contact_inbox
      )
    end
  end

  def create_message
    message = @conversation.messages.build(
      content: params[:message],
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: :incoming,
      sender: @contact,
      source_id: params[:message_id]
    )
    
    message.save!
  end
end
