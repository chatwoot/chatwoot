class Digitaltolk::CreateTicketService
  attr_accessor :account, :params, :conversation

  ISSUE_TYPE_HASH = {
    '2nd Line Support' => '2nd-line-support',
    'Feedback' => 'feedback',
    'Question' => 'question'
  }.freeze

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
    @contact = contact.presence || create_contact
  end

  def create_conversation
    @conversation = ConversationBuilder.new(
      params: ActionController::Parameters.new(conversation_params),
      contact_inbox: @contact_inbox
    ).perform
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
    account.contacts.create!(contact_params)
  end

  def add_labels
    @labels = service_params[:labels] || []
    add_created_by_agent_label
    add_contact_kind_label
    add_issue_type_label
    return if @labels.blank?

    @conversation.update_labels(@labels.uniq)
  end

  def auto_assign_created_by_agent_label
    return if @conversation.cached_label_list.to_s.include?(Label::CREATED_BY_AGENT)

    @conversation.reload.add_labels(Label::CREATED_BY_AGENT)
  end

  def add_created_by_agent_label
    @labels << Label::CREATED_BY_AGENT
  end

  def add_contact_kind_label
    return if params[:contact_kind].blank?

    label = Digitaltolk::ChangeContactKindService::KIND_LABELS[params[:contact_kind].to_i]
    @labels << label if label.present?
  end

  def add_issue_type_label
    return if params[:issue_type].blank?

    label = ISSUE_TYPE_HASH[params[:issue_type].to_s]
    @labels << label if label.present?
  end

  def contact_params
    {
      name: service_params[:name],
      phone_number: phone,
      email: email
    }
  end

  def conversation_params
    {
      team_id: service_params[:team_id],
      custom_attributes: service_params[:custom_attributes].permit!.to_h.symbolize_keys,
      status: service_params[:status],
      additional_attributes: {
        ticket: true,
        mail_subject: service_params[:subject]
      }
    }
  end

  def message_params
    {
      private: service_params[:private],
      content: service_params[:note],
      cc_emails: service_params[:cc_emails],
      bcc_emails: service_params[:bcc_emails]
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
