class Api::V1::Widget::ContactsController < Api::V1::Widget::BaseController
  include WidgetHelper

  before_action :validate_hmac, only: [:set_user]
  before_action :ensure_contact_present, except: [:set_user]
  rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid

  def show
    render json: @contact.present? ? contact_with_push_token : { error: 'Contact not found' }, status: @contact.present? ? :ok : :not_found
  end

  def update
    identify_contact(@contact)
    update_push_token if push_token_param.present?
    render json: contact_with_push_token
  end

  def set_user
    contact = nil

    if a_different_contact?
      @contact_inbox, @widget_auth_token = build_contact_inbox_with_token(@web_widget)
      contact = @contact_inbox.contact
    else
      contact = @contact
    end

    @contact_inbox.update(hmac_verified: true) if should_verify_hmac?

    identify_contact(contact)
    update_push_token if push_token_param.present?
    render json: contact_with_push_token
  end

  # TODO : clean up this with proper routes delete contacts/custom_attributes
  def destroy_custom_attributes
    @contact.custom_attributes = @contact.custom_attributes.excluding(params[:custom_attributes])
    @contact.save!
    render json: contact_with_push_token
  end

  # Method to update push token
  def update_push_token
    render json: { error: 'Contact not found' }, status: :not_found and return unless @contact.present?

    @contact.update!(push_token: push_token_param)
    render json: contact_with_push_token
  end

  private

  def identify_contact(contact)
    contact_identify_action = ContactIdentifyAction.new(
      contact: contact,
      params: permitted_params.to_h.deep_symbolize_keys,
      discard_invalid_attrs: true
    )
    @contact = contact_identify_action.perform
  end

  def a_different_contact?
    @contact.identifier.present? && @contact.identifier != permitted_params[:identifier]
  end

  def validate_hmac
    return unless should_verify_hmac?

    render json: { error: 'HMAC failed: Invalid Identifier Hash Provided' }, status: :unauthorized unless valid_hmac?
  end

  def should_verify_hmac?
    return false if params[:identifier_hash].blank? && !@web_widget.hmac_mandatory

    # Taking an extra caution that the hmac is triggered whenever identifier is present
    return false if params[:custom_attributes].present? && params[:identifier].blank?

    true
  end

  def valid_hmac?
    params[:identifier_hash] == OpenSSL::HMAC.hexdigest(
      'sha256',
      @web_widget.hmac_token,
      params[:identifier].to_s
    )
  end

  def permitted_params
    params.permit(:website_token, :identifier, :identifier_hash, :email, :name, :avatar_url, :phone_number, :push_token, :plate_number,
                  custom_attributes: {}, additional_attributes: {})
  end

  def push_token_param
    params[:push_token]
  end

  def ensure_contact_present
    render json: { error: 'Contact not found' }, status: :not_found unless @contact.present?
  end

  def render_record_invalid(exception)
    render json: { error: exception.record.errors.full_messages.join(', ') }, status: :unprocessable_entity
  end

  # Include push token in response
  def contact_with_push_token
    @contact.attributes
  end
end
