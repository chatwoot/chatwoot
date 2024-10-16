class Onehash::Api::ContactsController < Onehash::IntegrationController
  before_action :validate_params, only: [:create]

  def index
    contacts = Contact.all
    render json: contacts, status: :ok
  end

  def create
    # Check if contact already exists
    existing_contact = Contact.find_by(email: contact_params[:email], account: params[:account_id])

    if existing_contact
      return render json: existing_contact, status: :ok # Return existing contact as a success response
    end

    # Create new contact
    contact = Contact.new(contact_params.merge(account_id: params[:account_id]))

    if contact.save
      render json: contact, status: :created
    else
      render json: contact.errors, status: :unprocessable_entity
    end
  end

  private

  def contact_params
    params.require(:contact).permit(:email, :name, :phone_number)
  end

  def validate_params
    # Check if name and account_id are present
    name_present = params[:contact][:name].present?
    account_id_present = params[:account_id].present?

    # Check if at least one of email or phone_number is present
    at_least_one_contact_field_present = contact_params[:email].present? || contact_params[:phone_number].present?

    return if name_present && account_id_present && at_least_one_contact_field_present

    render json: { error: 'At least one of email or phone_number, along with name and account_id, is required' }, status: :bad_request
  end
end
