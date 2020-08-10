class Api::V1::Accounts::Contacts::ContactInboxesController < Api::V1::Accounts::BaseController
  before_action :ensure_contact
  before_action :ensure_inbox, only: [:create]
  before_action :validate_channel_type

  def create
    source_id = params[:source_id] || SecureRandom.uuid
    @contact_inbox = ContactInbox.create(contact: @contact, inbox: @inbox, source_id: source_id)
  end

  private

  def validate_channel_type
    return if @inbox.channel_type == 'Channel::Api'

    render json: { error: 'Contact Inbox creation is only allowed in API inboxes' }, status: :unprocessable_entity
  end

  def ensure_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
  end

  def ensure_contact
    @contact = Current.account.contacts.find(params[:contact_id])
  end
end
