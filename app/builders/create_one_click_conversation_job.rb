class CreateOneClickConversationJob < ApplicationJob
  queue_as :critical

  def build_contact_inbox(new_contact, inbox)
    ContactInboxBuilder.new(
      contact: new_contact,
      inbox: inbox
    ).perform
  end

  def perform(contact, inbox_id, account, user, message, is_from_whatsapp, mail_subject = nil) # rubocop:disable Metrics/ParameterLists
    cache_key = "create_one_click_conversations:#{inbox_id}:#{contact[:email]}:#{contact[:phone_number]}"

    Rails.logger.info("MEssage iNside job #{message.inspect}")

    cache_value = Rails.cache.read(cache_key)

    return if cache_value == 'running'

    Rails.cache.write(cache_key, 'running')

    @inbox = Inbox.find_by(id: inbox_id)
    raise ActiveRecord::RecordNotFound, 'Inbox not found' unless @inbox

    @contact = find_or_create_contact(contact, account, is_from_whatsapp)
    @contact.save!
    @contact_inbox = build_contact_inbox(@contact, @inbox)

    conversation = find_or_create_conversation(@contact, @contact_inbox, mail_subject)

    # Send the initial message
    Messages::MessageBuilder.new(user, conversation, message).perform
  ensure
    Rails.cache.delete(cache_key)
  end

  private

  def find_or_create_contact(contact, account, is_from_whatsapp)
    email = contact[:email]
    phone_number = contact[:phone_number]

    is_whatsapp = is_from_whatsapp != 'false'

    existing_contact = if is_whatsapp
                         Contact.find_by(account_id: account.id, phone_number: phone_number)
                       else
                         Contact.find_by(account_id: account.id, email: email)
                       end

    return existing_contact if existing_contact

    account.contacts.new(contact)
  end

  def find_or_create_conversation(contact, contact_inbox, mail_subject)
    Rails.logger.info("contact, #{contact.inspect}")
    latest_conversation = contact.conversations.order(created_at: :desc).first

    if latest_conversation.blank?
      params = {}
      params[:additional_attributes] = mail_subject.present? ? ActionController::Parameters.new({ mail_subject: mail_subject }) : {}
      conversation = ConversationBuilder.new(params: params, contact_inbox: contact_inbox).perform
      return conversation
    elsif latest_conversation.status != 'open'
      additional_attributes = latest_conversation.additional_attributes || {}
      additional_attributes[:mail_subject] = mail_subject if mail_subject.present?
      latest_conversation.update!(status: 'open', additional_attributes: additional_attributes)
    end
    latest_conversation
  end
end
