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
      @contact = Current.account.contacts.new(contact_params)
      @contact.save!
      @contact_inbox = build_contact_inbox
    end
  end

  def update
    @contact.update!(contact_update_params)
  rescue ActiveRecord::RecordInvalid => e
    render json: {
      message: e.record.errors.full_messages.join(', '),
      contact: Contact.find_by(email: contact_params[:email])
    }, status: :unprocessable_entity
  end

  def search
    render json: { error: 'Specify search string with parameter q' }, status: :unprocessable_entity if params[:q].blank? && return

    @contacts = Current.account.contacts.where('name LIKE :search OR email LIKE :search', search: "%#{params[:q]}%")
  end

  private

  def check_authorization
    authorize(Contact)
  end

  def build_contact_inbox
    return if params[:inbox_id].blank?

    inbox = Current.account.inboxes.find(params[:inbox_id])
    source_id = params[:source_id] || SecureRandom.uuid
    ContactInbox.create(contact: @contact, inbox: inbox, source_id: source_id)
  end

  def contact_params
    params.require(:contact).permit(:name, :email, :phone_number, additional_attributes: {}, custom_attributes: {})
  end

  def contact_custom_attributes
    return @contact.custom_attributes.merge(contact_params[:custom_attributes]) if contact_params[:custom_attributes]

    @contact.custom_attributes
  end

  def contact_update_params
    # we want the merged custom attributes not the original one
    contact_params.except(:custom_attributes).merge({ custom_attributes: contact_custom_attributes })
  end

  def fetch_contact
    @contact = Current.account.contacts.includes(contact_inboxes: [:inbox]).find(params[:id])
  end
end
