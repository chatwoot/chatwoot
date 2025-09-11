class Waha::IncomingMessageService
  pattr_initialize [:params!]

  def perform
    return if waha_channel.blank?

    begin
      set_contact
      set_conversation
      create_message
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "WAHA VALIDATION FAILED: #{e.record.errors.full_messages.to_sentence}"
      Rails.logger.error e.backtrace.join("\n")
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
    # sender_phone = params[:sender].to_s
    # cleaned_source_id = sender_phone.split(':').first.split('@').first
    # formatted_phone_number = cleaned_source_id.start_with?('+') ? cleaned_source_id : "+#{cleaned_source_id}"

    contact_inbox = ContactInboxWithContactBuilder.new(
      source_id: cleaned_source_id,
      inbox: inbox,
      contact_attributes: {
        name: params[:sender_name],
        phone_number: formatted_phone_number
      }
    ).perform

    @contact_inbox = contact_inbox
    @contact = contact_inbox.contact
  end

  def set_conversation
    @conversation = @contact.conversations.where(inbox: inbox).last

    return unless @conversation.blank? || @conversation.resolved?

    @conversation = Conversation.create!(
      account_id: @contact.account_id,
      inbox: inbox,
      contact: @contact,
      contact_inbox: @contact_inbox
    )
  end

  def create_message
    message = @conversation.messages.build(
      content: params[:message],
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: :incoming,
      sender: @contact,
      source_id: params[:message_id],
      additional_attributes: {
        name: params[:sender_name],
        phone_number: formatted_phone_number,
        channel: 'WhatsappUnofficial'
      }
    )

    message.save!
  end

  def cleaned_source_id
    sender_phone = params[:sender].to_s
    @cleaned_source_id ||= sender_phone.split(':').first.split('@').first
  end

  def formatted_phone_number
    @formatted_phone_number ||= @cleaned_source_id.start_with?('+') ? @cleaned_source_id : "+#{@cleaned_source_id}"
  end
end
