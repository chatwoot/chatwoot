class Api::V1::Widget::ContactsController < Api::V1::Widget::BaseController
  include WidgetHelper

  before_action :validate_hmac, only: [:set_user]

  def show; end

  def update
    identify_contact(@contact)
  end

  def set_user
    contact = nil

    if a_different_contact?
      @contact_inbox, @widget_auth_token = build_contact_inbox_with_token(@web_widget)
      contact = @contact_inbox.contact
    else
      contact = @contact
    end

    @contact_inbox.update(hmac_verified: true) if should_verify_hmac? && valid_hmac?

    identify_contact(contact)
  end

  # TODO : clean up this with proper routes delete contacts/custom_attributes
  def destroy_custom_attributes
    @contact.custom_attributes = @contact.custom_attributes.excluding(params[:custom_attributes])
    @contact.save!
    render json: @contact
  end

  def verify_shopify_email
    Rails.logger.info("Verify shopify email")
    # Currently skipping all otp logic
    email = params[:email]
    if @contact.email.present? && params[:email] == ''
      email = @contact.email
    else
      contact = Contact.find_by(email: email)      
      return render json: {error: "No contact found"}, status: :not_found unless contact
      identify_contact(contact)

      @contact.update(custom_attributes: @contact.custom_attributes.merge({shopify_new_login: true}))

      send_verification_otp
    end
  end

  def verify_shopify_otp
    code = params.permit(:otp)[:otp]
    original_code = @contact.custom_attributes['shopify_otp']
    expiry = @contact.custom_attributes['shopify_otp_expiry']

    return render json: {error: "Otp expired"}, status: :gone if expiry < Time.current

    Rails.logger.info("Codes: #{code}, #{original_code}")
    return render json: {error: "Otp invalid"}, status: :unauthorized if code != original_code

    @contact.update(custom_attributes: @contact.custom_attributes.merge({shopify_verified_email: @contact.email, shopify_new_login: false}))
    
    if (!@contact.custom_attributes['shopify_customer_id'].present?)
      Rails.logger.info("Populating")
      PopulateShopifyContactDataJob.perform_now(
        account_id: inbox.account.id,
        id: @contact.id,
        email: params[:email],
        phone_number: @contact.phone_number,
      );
    end

    render json: {
      shopify_customer_id: @contact.custom_attributes['shopify_customer_id']
    }, status: :ok
  end

  def send_verification_otp
    code = Array.new(6) { rand(0..9) }.join

    # ContactMailer.otp_email(contact: @contact, subject: "Otp verification for your shopify account", otp: code, account: inbox.account).deliver_now
    sleep 2

    @contact.update(custom_attributes: @contact.custom_attributes.merge({
      shopify_otp: code,
      shopify_otp_expiry: 10.minutes.from_now
    }))
  end

  def identify_contact(contact)
    contact_identify_action = ContactIdentifyAction.new(
      contact: @contact,
      params: permitted_params.to_h.deep_symbolize_keys,
      retain_original_contact_name: true,
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
    params.permit(:website_token, :identifier, :identifier_hash, :email, :name, :avatar_url, :phone_number, custom_attributes: {},
                                                                                                            additional_attributes: {})
  end
end
