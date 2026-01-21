class Api::V1::Widget::ContactsController < Api::V1::Widget::BaseController # rubocop:disable Metrics/ClassLength
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

  def get_url_for_whatsapp_widget # rubocop:disable Naming/AccessorMethodName
    @web_widget = ::Channel::WebWidget.find_by!(website_token: permitted_params[:website_token])
    inbox_id = @web_widget.inbox.id
    account_id = @web_widget.account.id

    additional_attributes = @web_widget.additional_attributes

    is_chat_on_whatsapp = additional_attributes.dig('chat_on_whatsapp_settings', 'enabled')

    return render json: { error: 'Inbox ID not found' }, status: :bad_request if inbox_id.blank?
    return render json: { error: 'Account Id Not Found' }, status: :bad_request if account_id.blank?
    return render json: { error: 'Chat on Whatsapp not enabled' }, status: :bad_request unless is_chat_on_whatsapp

    default_text = additional_attributes.dig('chat_on_whatsapp_settings', 'default_text')
    phone_number = additional_attributes.dig('chat_on_whatsapp_settings', 'phone_number')

    shop_url = fetch_shop_url_from_api(account_id)

    response = fetch_whatsapp_widget_url(shop_url, default_text, phone_number)
    render json: response
  end

  def bot_config
    @web_widget = ::Channel::WebWidget.find_by!(website_token: permitted_params[:website_token])
    account_id = @web_widget.account.id

    return render json: { error: 'Account Id Not Found' }, status: :bad_request if account_id.blank?

    shop_url = fetch_shop_url_from_api(account_id)

    Rails.logger.info("shop_urlData, #{shop_url}")

    return render json: { error: 'Shop Url Not Found' }, status: :bad_request if shop_url.blank?

    response = fetch_live_chat_bot_config(shop_url)
    render json: response
  end

  def update_bot_config
    @web_widget = ::Channel::WebWidget.find_by!(website_token: permitted_params[:website_token])
    account_id = @web_widget.account.id

    return render json: { error: 'Account Id Not Found' }, status: :bad_request if account_id.blank?

    shop_url = fetch_shop_url_from_api(account_id)

    return render json: { error: 'Shop Url Not Found' }, status: :bad_request if shop_url.blank?

    popup_id = permitted_params[:popup_id]

    response = update_popup_id_in_bot_config(shop_url, popup_id)
    render json: response
  end

  def send_main_menu_message
    inbox_id = conversation.inbox.id
    account_id = conversation.inbox.account.id

    return render json: { error: 'Inbox ID not found' }, status: :bad_request if inbox_id.blank?
    return render json: { error: 'Account Id Not Found' }, status: :bad_request if account_id.blank?

    contact_inbox = @contact.contact_inboxes.find_by(inbox_id: inbox_id)
    shop_url = fetch_shop_url_from_api(account_id)
    source_id = contact_inbox.source_id

    return render json: { error: 'Shop URL not found' }, status: :bad_request if shop_url.blank?
    return render json: { error: 'Source ID not found' }, status: :bad_request if source_id.blank?

    response = fetch_main_menu_message(shop_url, source_id)
    if response
      render json: response
    else
      render json: { error: 'Failed to send main menu message' }, status: :internal_server_error
    end
  end

  def send_custom_need_help_message # rubocop:disable Metrics/AbcSize
    @web_widget = ::Channel::WebWidget.find_by!(website_token: permitted_params[:website_token])
    custom_message = @web_widget.additional_attributes['need_more_help_custom_message']

    return render json: { error: 'Custom message not configured' }, status: :bad_request if custom_message.blank?
    return render json: { error: 'Conversation not found' }, status: :bad_request if conversation.blank?

    message = conversation.messages.create!(
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :outgoing,
      content: custom_message,
      sender: conversation.assignee || bot_user
    )

    render json: { success: true, message_id: message.id }
  rescue StandardError => e
    Rails.logger.error "Error sending custom need help message: #{e.message}"
    render json: { error: 'Failed to send custom message' }, status: :internal_server_error
  end

  def get_checkout_url # rubocop:disable Naming/AccessorMethodName, Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity
    inbox_id = conversation.inbox.id
    account_id = conversation.inbox.account.id

    return render json: { error: 'Inbox ID not found' }, status: :bad_request if inbox_id.blank?

    contact_inbox = @contact.contact_inboxes.find_by(inbox_id: inbox_id)
    shop_url = permitted_params[:shop_url]
    source_id = contact_inbox.source_id

    Rails.logger.info("source_id, #{source_id}")
    Rails.logger.info("account_id, #{account_id}")
    Rails.logger.info("get_checkout_url_called_Params, #{permitted_params[:line_items]}")

    # For account ID 1904, redirect to product page when clicking "Buy Now"
    if [1904].include?(account_id)
      Rails.logger.info("Account ID #{account_id} detected, checking for product page redirect")

      begin
        line_items = JSON.parse(permitted_params[:line_items])

        # If there's exactly one item (Buy Now scenario), redirect to product page
        if line_items.length == 1
          first_item = line_items.first
          variant_id = first_item['variant_id']
          product_handle = first_item['product_handle']

          if product_handle.present?
            Rails.logger.info("Redirecting to product page for variant #{variant_id} with handle #{product_handle}")
            response = { 'checkoutUrl' => "https://#{shop_url}/products/#{product_handle}?variant=#{variant_id}" }
          else
            # Fallback to cart if product handle not provided
            Rails.logger.warn("Product handle not found in line_items for variant #{variant_id}, falling back to cart")
            response = { 'checkoutUrl' => "https://#{shop_url}/cart" }
          end
        else
          # Multiple items, redirect to cart
          Rails.logger.info('Multiple items in cart, redirecting to cart page')
          response = { 'checkoutUrl' => "https://#{shop_url}/cart" }
        end
      rescue JSON::ParserError => e
        Rails.logger.error("Error parsing line_items: #{e.message}")
        response = { 'checkoutUrl' => "https://#{shop_url}/cart" }
      end
    else
      response = fetch_checkout_url(shop_url, source_id, permitted_params[:line_items])
    end

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
    params.permit(:website_token, :line_items, :shop_url, :identifier, :identifier_hash, :email, :name, :avatar_url, :phone_number, :popup_id, custom_attributes: {}, # rubocop:disable Layout/LineLength
                                                                                                                                               additional_attributes: {}) # rubocop:disable Layout/LineLength
  end
end
