class Digitaltolk::CreateTicketService
  attr_accessor :account, :params, :conversation

  def initialize(account, params)
    @account = account
    @params = params
  end

  def perform
    find_or_create_contact
    create_contact_inbox
    create_conversation
    create_note
    add_labels
  end

  private

  def find_or_create_contact
    contact = account.contacts.from_email(email)

    if contact.blank?
      contact = account.contacts.find_by(phone_number: phone)
    end

    @contact = contact.presence || create_contact
  end

  def create_conversation
    @conversation = ConversationBuilder.new(params: ActionController::Parameters.new(conversation_params), contact_inbox: @contact_inbox).perform
  end

  def create_contact_inbox
    @contact_inbox = ContactInboxBuilder.new(
      contact: @contact,
      inbox: inbox
    ).perform
  end

  def create_note
    Messages::MessageBuilder.new(Current.user, @conversation, message_params).perform
  end

  def inbox
    account.inboxes.find_by(id: inbox_id)
  end

  def inbox_id
    service_params[:inbox_id]
  end

  def create_contact
    account.contacts.create(contact_params)
  end

  def add_labels
    return if service_params[:labels].blank?

    @conversation.update_labels(service_params[:labels])
  end

  def contact_params
    {
      name: service_params.dig(:name),
      phone_number: phone,
      email: email
    }
  end

  def conversation_params
    {
      team_id: service_params[:team_id],
      additional_attributes: { ticket: true },
      custom_attributes: service_params[:custom_attributes].permit!.to_h.symbolize_keys
    }
  end

  def message_params
    {
      private: true,
      content: service_params[:note]
    }
  end
  
  def email
    service_params[:email].to_s.downcase
  end

  def phone
    [params[:phoneCode], service_params[:phone]].compact.join
  end

  def service_params
    params.permit!
  end
end