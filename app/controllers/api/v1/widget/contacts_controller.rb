class Api::V1::Widget::ContactsController < Api::V1::Widget::BaseController
  include WidgetHelper

  before_action :validate_hmac, only: [:set_user, :update], if: -> { action_name == 'set_user' || params[:identifier].present? }

  def show; end

  def update
    return set_user if permitted_params[:identifier].present?

    identify_contact(@contact)
  end

  def set_user
    @contact_inbox, @widget_auth_token = build_contact_inbox_with_token(@web_widget) if a_different_contact?
    identify_contact(@contact_inbox.contact)
    render :set_user
  end

  # TODO : clean up this with proper routes delete contacts/custom_attributes
  def destroy_custom_attributes
    @contact.custom_attributes = @contact.custom_attributes.excluding(params[:custom_attributes])
    @contact.save!
    render json: @contact
  end

  private

  def identify_contact(contact)
    contact_identify_action = ContactIdentifyAction.new(
      contact: contact,
      params: permitted_params.to_h.deep_symbolize_keys,
      discard_invalid_attrs: true
    )
    @contact = contact_identify_action.perform
    @contact_inbox.reload
    @contact_inbox.update!(hmac_verified: true) if @verified_identifier.present? && @contact.identifier == @verified_identifier
  end

  def a_different_contact?
    (@contact.identifier.present? || @contact_inbox.hmac_verified?) && @contact.identifier != permitted_params[:identifier].to_s
  end

  def validate_hmac
    return if params[:identifier_hash].blank? && !@web_widget.hmac_mandatory
    return if params[:custom_attributes].present? && params[:identifier].blank?
    return render json: { error: 'HMAC failed: Invalid Identifier Hash Provided' }, status: :unauthorized unless valid_hmac?

    @verified_identifier = params[:identifier].to_s
  end

  def valid_hmac?
    return false if params[:identifier].blank?

    expected_hash = OpenSSL::HMAC.hexdigest(
      'sha256',
      @web_widget.hmac_token,
      params[:identifier].to_s
    )
    identifier_hash = params[:identifier_hash].to_s
    return false unless identifier_hash.bytesize == expected_hash.bytesize

    ActiveSupport::SecurityUtils.secure_compare(identifier_hash, expected_hash)
  end

  def permitted_params
    params.permit(:website_token, :identifier, :identifier_hash, :email, :name, :avatar_url, :phone_number, custom_attributes: {},
                                                                                                            additional_attributes: {})
  end
end
