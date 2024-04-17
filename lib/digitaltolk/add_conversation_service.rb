class Digitaltolk::AddConversationService
  attr_accessor :inbox_id, :params

  def initialize(inbox_id, params)
    @inbox_id = inbox_id
    @params = params
  end

  def perform
    find_or_create_contact

    ConversationBuilder.new(params: ActionController::Parameters.new(conversation_params), contact_inbox: @contact_inbox).perform
  end

  private

  def inbox
    @inbox ||= Inbox.find_by(id: @inbox_id)
  end

  def find_or_create_contact
    @contact = inbox.contacts.find_by(email: email_address)

    if @contact.present?
      @contact_inbox = ContactInbox.find_by(inbox: @inbox, contact: @contact)
    else
      create_contact
    end
  end

  def create_contact
    @contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: email_address,
      inbox: inbox,
      contact_attributes: {
        name: identify_contact_name,
        email: email_address,
        additional_attributes: {
          source_id: 'email:'
        }
      }
    ).perform
    @contact = @contact_inbox.contact
  end

  def email_address
    params[:email]
  end

  def identify_contact_name
    email_address.split('@').first
  end

  def conversation_params
    {
      account_id: params[:account_id],
      assignee_id: params[:assignee_id],
      contact_id: @contact.id,
      inbox_id: params[:inbox_id],
      source_id: params[:email],
      additional_attributes: {
        mail_subject: params[:subject]
      },
      message: {
        content: params[:content]
      }
    }
  end
end
