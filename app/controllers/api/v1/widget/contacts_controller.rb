class Api::V1::Widget::ContactsController < Api::V1::Widget::BaseController
  include WidgetHelper

  # The identify endpoint accepts a signed token only.
  TOKEN_STRATEGIES = [ContactIdentity::Strategies::JwtStrategy].freeze

  before_action :validate_hmac, only: [:set_user]
  before_action :validate_hmac_for_identified_update, only: [:update]

  def show; end

  def update
    identify_contact(@contact)
  end

  def set_user
    contact = session_contact_for(permitted_params[:identifier])

    @contact_inbox.update(hmac_verified: true) if should_verify_hmac?

    identify_contact(contact)
  end

  def identify
    proof = ContactIdentity::Verifier.new(channel: @web_widget, identifier: nil, params: params, strategies: TOKEN_STRATEGIES).perform
    return render_unauthorized(I18n.t('errors.contact_identity.invalid_token')) unless proof.verified?

    contact = session_contact_for(proof.identifier)
    @contact_inbox.update(hmac_verified: true)
    @contact = ContactIdentifyAction.new(
      contact: contact,
      params: proof.attributes.symbolize_keys.merge(identifier: proof.identifier),
      contact_inbox: @contact_inbox,
      discard_invalid_attrs: true,
      verification_source: VerifiableAttributes::SOURCE_JWT
    ).perform
    render :set_user
  end

  # TODO : clean up this with proper routes delete contacts/custom_attributes
  def destroy_custom_attributes
    @contact.custom_attributes = @contact.custom_attributes.excluding(params[:custom_attributes])
    @contact.save!
    render :update
  end

  private

  def identify_contact(contact)
    contact_identify_action = ContactIdentifyAction.new(
      contact: contact,
      params: permitted_params.to_h.deep_symbolize_keys,
      contact_inbox: @contact_inbox,
      discard_invalid_attrs: true
    )
    @contact = contact_identify_action.perform
  end

  # A session that belongs to another identified contact moves to a new contact with its own session token.
  def session_contact_for(identifier)
    return @contact unless @contact.identifier.present? && @contact.identifier != identifier

    @contact_inbox, @widget_auth_token = build_contact_inbox_with_token(@web_widget)
    @contact_inbox.contact
  end

  # The plain update endpoint is also used for anonymous prechat updates
  # (name/email/phone/custom_attributes with no identifier), which must keep
  # working on hmac_mandatory inboxes. Only the identity-binding path, where an
  # identifier is supplied and the contact can be rebound, requires HMAC.
  def validate_hmac_for_identified_update
    return if params[:identifier].blank?

    validate_hmac
  end

  def validate_hmac
    return unless should_verify_hmac?

    render json: { error: 'HMAC failed: Invalid Identifier Hash Provided' }, status: :unauthorized unless identity_proof.verified?
  end

  def should_verify_hmac?
    return false if identity_proof.none? && !@web_widget.hmac_mandatory

    # Taking an extra caution that the hmac is triggered whenever identifier is present
    return false if params[:custom_attributes].present? && params[:identifier].blank?

    true
  end

  def identity_proof
    @identity_proof ||= ContactIdentity::Verifier.new(channel: @web_widget, identifier: params[:identifier], params: params).perform
  end

  def permitted_params
    params.permit(:website_token, :identifier, :identifier_hash, :email, :name, :avatar_url, :phone_number, custom_attributes: {},
                                                                                                            additional_attributes: {})
  end
end
