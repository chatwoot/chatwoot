class Api::V1::Widget::ContactsController < Api::V1::Widget::BaseController
  include WidgetHelper

  before_action :validate_hmac, only: [:set_user]

  def show; end

  def update
    identify_contact(@contact)
  end

  def get_whatsapp_redirect_url # rubocop:disable Naming/AccessorMethodName
    inbox_id = conversation.inbox.id
    account_id = conversation.inbox.account.id
    @web_widget = ::Channel::WebWidget.find_by!(website_token: permitted_params[:website_token])

    need_more_help_type = @web_widget.need_more_help_type

    return render json: { error: 'Inbox ID not found' }, status: :bad_request if inbox_id.blank?
    return render json: { error: 'Account Id Not Found' }, status: :bad_request if account_id.blank?

    contact_inbox = @contact.contact_inboxes.find_by(inbox_id: inbox_id)

    shop_url = fetch_shop_url_from_api(account_id)
    source_id = contact_inbox.source_id

    if need_more_help_type == 'redirect_to_whatsapp'
      response = fetch_whatsapp_redirect_url(shop_url, source_id, conversation.display_id)
      render json: response
    else
      render json: { error: 'Redirect to whatsappFailed' }, status: :not_found
    end
  end

  def get_checkout_url # rubocop:disable Naming/AccessorMethodName
    inbox_id = conversation.inbox.id

    return render json: { error: 'Inbox ID not found' }, status: :bad_request if inbox_id.blank?

    contact_inbox = @contact.contact_inboxes.find_by(inbox_id: inbox_id)
    shop_url = permitted_params[:shop_url]
    source_id = contact_inbox.source_id

    Rails.logger.info("get_checkout_url_called_Params, #{permitted_params[:line_items]}")

    response = fetch_checkout_url(shop_url, source_id, permitted_params[:line_items])
    Rails.logger.info("response, #{response.inspect}")
    render json: response
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
    params.permit(:website_token, :line_items, :shop_url, :identifier, :identifier_hash, :email, :name, :avatar_url, :phone_number, custom_attributes: {}, # rubocop:disable Layout/LineLength
                                                                                                                                    additional_attributes: {}) # rubocop:disable Layout/LineLength
  end
end
