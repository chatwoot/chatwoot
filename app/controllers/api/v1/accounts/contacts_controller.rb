class Api::V1::Accounts::ContactsController < Api::V1::Accounts::BaseController
  protect_from_forgery with: :null_session

  before_action :check_authorization
  before_action :fetch_contact, only: [:show, :update]

  def index
    @contacts = Current.account.contacts
  end

  def show; end

  def create
    @contact = Current.account.contacts.new(contact_create_params)
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
    @contact = Current.account.contacts.find(params[:id])
  end

  def contact_create_params
    params.require(:contact).permit(:name, :email, :phone_number)
  end
end
