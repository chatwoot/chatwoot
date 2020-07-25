class Api::V1::Accounts::ContactsController < Api::V1::Accounts::BaseController
  protect_from_forgery with: :null_session

  before_action :check_authorization
  before_action :fetch_contact, only: [:show, :update]

  def index
    @contacts = Current.account.contacts
  end

  def show; end

  def create
    ActiveRecord::Base.transaction do
      @contact = Current.account.contacts.new(contact_create_params)
      @contact.save!
      @contact_inbox = build_contact_inbox
    end
  end

  def update
    @contact.update!(contact_params)
  end

  private

  def check_authorization
    authorize(Contact)
  end

  def build_contact_inbox
    return if params[:inbox_id].blank?

    inbox = Inbox.find(params[:inbox_id])
    source_id = params[:source_id] || SecureRandom.uuid
    ContactInbox.create(contact: @contact, inbox: inbox, source_id: source_id)
  end

  def contact_params
    params.require(:contact).permit(:name, :email, :phone_number)
  end

  def fetch_contact
    @contact = Current.account.contacts.find(params[:id])
  end

  def contact_create_params
    params.require(:contact).permit(:name, :email, :phone_number)
  end
end
