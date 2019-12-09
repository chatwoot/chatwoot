class Api::V1::ContactsController < Api::BaseController
  protect_from_forgery with: :null_session

  before_action :check_authorization
  before_action :fetch_contact, only: [:show, :update]

  skip_before_action :authenticate_user!, only: [:create]
  skip_before_action :set_current_user, only: [:create]
  skip_before_action :check_subscription, only: [:create]
  skip_around_action :handle_with_exception, only: [:create]

  def index
    @contacts = current_account.contacts
  end

  def show; end

  def create
    @contact = Contact.new(contact_create_params)
    @contact.save!
    render json: @contact
  end

  def update
    @contact.update!(contact_params)
  end

  private

  def check_authorization
    authorize(Contact)
  end

  def contact_params
    params.require(:contact).permit(:name, :email, :phone_number)
  end

  def fetch_contact
    @contact = current_account.contacts.find(params[:id])
  end

  def contact_create_params
    params.require(:contact).permit(:account_id, :inbox_id).merge!(name: SecureRandom.hex)
  end
end
