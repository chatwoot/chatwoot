class Api::V1::Accounts::Contacts::CallsController < Api::V1::Accounts::BaseController
  before_action :fetch_contact

  def create
    # Validate that contact has a phone number
    if @contact.phone_number.blank?
      render json: { error: 'Contact has no phone number' }, status: :unprocessable_entity
      return
    end

    begin
      # Use the outgoing call service to handle the entire process
      service = Voice::OutgoingCallService.new(
        account: Current.account,
        contact: @contact,
        user: Current.user
      )
      
      # Process the call - this handles all the steps
      conversation = service.process
      
      # Assign to @conversation so jbuilder template can access it
      @conversation = conversation

      # Use the conversation jbuilder template to ensure consistent representation
      # This will ensure only display_id is used as the id, not the internal database id
      render 'api/v1/accounts/conversations/show'
    rescue StandardError => e
      Rails.logger.error("Error initiating call: #{e.message}")
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  private

  def fetch_contact
    @contact = Current.account.contacts.find(params[:contact_id])
  end
end