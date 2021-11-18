class Api::V1::Widget::ContactsController < Api::V1::Widget::BaseController
  before_action :process_hmac

  def show; end

  def update
    contact_identify_action = ContactIdentifyAction.new(
      contact: @contact,
      params: permitted_params.to_h.deep_symbolize_keys
    )
    render json: contact_identify_action.perform
  end

  # TODO : clean up this with proper routes delete contacts/custom_attributes
  def destroy_custom_attributes
    @contact.custom_attributes = @contact.custom_attributes.excluding(params[:custom_attributes])
    @contact.save!
    render json: @contact
  end

  private

  def process_hmac
    return if params[:identifier_hash].blank? && !@web_widget.hmac_mandatory

    render json: { error: 'HMAC failed: Invalid Identifier Hash Provided' }, status: :unauthorized unless valid_hmac?

    @contact_inbox.update(hmac_verified: true)
  end

  def valid_hmac?
    params[:identifier_hash] == OpenSSL::HMAC.hexdigest(
      'sha256',
      @web_widget.hmac_token,
      params[:identifier].to_s
    )
  end

  def permitted_params
    params.permit(:website_token, :identifier, :identifier_hash, :email, :name, :avatar_url, :phone_number, custom_attributes: {})
  end
end
