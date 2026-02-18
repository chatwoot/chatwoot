# YCloud webhook payload format:
# https://docs.ycloud.com/reference/whatsapp-inbound-message-webhook-examples
#
# Inbound messages arrive as:
# {
#   "id": "evt_xxx",
#   "type": "whatsapp.inbound_message.received",
#   "whatsappInboundMessage": {
#     "id": "msg_id", "wamid": "wamid.xxx",
#     "from": "customer_phone", "to": "business_phone",
#     "customerProfile": { "name": "Customer Name" },
#     "type": "text", "text": { "body": "..." }, ...
#   }
# }
#
# Status updates arrive as:
# {
#   "id": "evt_xxx",
#   "type": "whatsapp.message.updated",
#   "whatsappMessage": { "id": "msg_id", "wamid": "wamid.xxx", "status": "delivered", ... }
# }
#
# Handles ALL 25 YCloud webhook event types.
class Whatsapp::IncomingMessageYcloudService < Whatsapp::IncomingMessageBaseService
  private

  def processed_params
    @processed_params ||= transform_ycloud_params
  end

  def transform_ycloud_params
    event_type = params[:type]

    case event_type
    when 'whatsapp.inbound_message.received'
      transform_inbound_message
    when 'whatsapp.message.updated'
      transform_status_update
    when 'whatsapp.template.reviewed'
      handle_template_reviewed
      {}
    when 'whatsapp.template.category_updated'
      handle_template_category_updated
      {}
    when 'whatsapp.template.quality_updated'
      handle_template_quality_updated
      {}
    when 'whatsapp.business_account.updated', 'whatsapp.business_account.reviewed'
      handle_business_account_event
      {}
    when 'whatsapp.business_account.deleted'
      handle_business_account_deleted
      {}
    when 'whatsapp.phone_number.deleted'
      handle_phone_number_deleted
      {}
    when 'whatsapp.phone_number.name_updated'
      handle_phone_number_name_updated
      {}
    when 'whatsapp.phone_number.quality_updated'
      handle_phone_number_quality_updated
      {}
    when 'whatsapp.payment.updated'
      handle_payment_updated
      {}
    when 'whatsapp.call.connect', 'whatsapp.call.terminate', 'whatsapp.call.status.updated'
      handle_call_event
      {}
    when 'whatsapp.flow.status_change'
      handle_flow_status_change
      {}
    when 'whatsapp.user.preferences'
      handle_user_preferences
      {}
    when 'whatsapp.smb.history'
      handle_smb_history
    when 'whatsapp.smb.message.echoes'
      handle_smb_message_echo
      {}
    when 'whatsapp.smb.app.state.sync'
      handle_smb_app_state_sync
      {}
    when 'contact.created', 'contact.deleted', 'contact.attributes_changed'
      handle_ycloud_contact_event
      {}
    when 'contact.unsubscribe.created', 'contact.unsubscribe.deleted'
      handle_unsubscribe_event
      {}
    else
      Rails.logger.info "YCloud: Unhandled webhook event type: #{event_type}"
      {}
    end
  end

  # --- Inbound message transformation ---

  def transform_inbound_message
    inbound = params[:whatsappInboundMessage]
    return {} if inbound.blank?

    # Handle order and product_inquiry types as special interactive messages
    msg_type = inbound[:type]
    if msg_type == 'order'
      return transform_order_message(inbound)
    elsif msg_type == 'product_inquiry'
      return transform_product_inquiry(inbound)
    end

    {
      contacts: [{
        profile: { name: inbound.dig(:customerProfile, :name) || inbound[:from] },
        wa_id: inbound[:from]
      }],
      messages: [build_message_from_inbound(inbound)]
    }
  end

  def build_message_from_inbound(inbound)
    message = {
      id: inbound[:wamid] || inbound[:id],
      from: inbound[:from],
      type: inbound[:type],
      timestamp: Time.zone.now.to_i.to_s
    }

    # Copy the type-specific payload (text, image, audio, video, document, location, contacts, button, interactive, sticker)
    type_key = inbound[:type]&.to_sym
    message[type_key] = inbound[type_key] if type_key && inbound[type_key].present?

    # Copy context for reply threading
    message['context'] = inbound[:context] if inbound[:context].present?

    # Copy referral data (click-to-WhatsApp ads)
    message[:referral] = inbound[:referral] if inbound[:referral].present?

    message
  end

  # Transform order messages (from WhatsApp Commerce catalog orders)
  def transform_order_message(inbound)
    order = inbound[:order]
    order_text = "Order received:\n"
    if order.present? && order[:productItems].present?
      order[:productItems].each do |item|
        order_text += "- #{item[:productRetailerId]}: #{item[:quantity]}x #{item[:itemPrice]} #{item[:currency]}\n"
      end
    end

    {
      contacts: [{
        profile: { name: inbound.dig(:customerProfile, :name) || inbound[:from] },
        wa_id: inbound[:from]
      }],
      messages: [{
        id: inbound[:wamid] || inbound[:id],
        from: inbound[:from],
        type: 'text',
        timestamp: Time.zone.now.to_i.to_s,
        text: { body: order_text }
      }]
    }
  end

  # Transform product inquiry messages
  def transform_product_inquiry(inbound)
    product = inbound[:productInquiry]
    inquiry_text = "Product inquiry: #{product&.dig(:productRetailerId) || 'Unknown product'}"

    {
      contacts: [{
        profile: { name: inbound.dig(:customerProfile, :name) || inbound[:from] },
        wa_id: inbound[:from]
      }],
      messages: [{
        id: inbound[:wamid] || inbound[:id],
        from: inbound[:from],
        type: 'text',
        timestamp: Time.zone.now.to_i.to_s,
        text: { body: inquiry_text }
      }]
    }
  end

  # --- Status update transformation ---

  def transform_status_update
    wa_message = params[:whatsappMessage]
    return {} if wa_message.blank?

    {
      statuses: [{
        id: wa_message[:wamid] || wa_message[:id],
        status: wa_message[:status],
        errors: wa_message[:whatsappApiError].present? ? [{ code: wa_message[:errorCode], title: wa_message[:errorMessage] }] : nil
      }.compact]
    }
  end

  # --- Template events ---

  def handle_template_reviewed
    template = params[:whatsappTemplate]
    return if template.blank?

    Rails.logger.info "YCloud: Template '#{template[:name]}' reviewed with status: #{template[:status]}"
    # Trigger a template sync to pick up the new status
    sync_templates_async
  end

  def handle_template_category_updated
    template = params[:whatsappTemplate]
    return if template.blank?

    Rails.logger.info "YCloud: Template '#{template[:name]}' category updated to: #{template[:category]}"
    sync_templates_async
  end

  def handle_template_quality_updated
    template = params[:whatsappTemplate]
    return if template.blank?

    Rails.logger.info "YCloud: Template '#{template[:name]}' quality updated to: #{template[:qualityScore]}"
    store_event_in_channel_config('template_quality_update', {
                                   name: template[:name],
                                   quality_score: template[:qualityScore],
                                   timestamp: Time.zone.now.iso8601
                                 })
  end

  # --- Business Account events ---

  def handle_business_account_event
    waba = params[:whatsappBusinessAccount]
    return if waba.blank?

    Rails.logger.info "YCloud: Business account #{waba[:id]} event: #{params[:type]}, status: #{waba[:accountReviewStatus]}"
    store_event_in_channel_config('business_account_update', {
                                   waba_id: waba[:id],
                                   status: waba[:accountReviewStatus],
                                   event: params[:type],
                                   timestamp: Time.zone.now.iso8601
                                 })
  end

  def handle_business_account_deleted
    waba = params[:whatsappBusinessAccount]
    Rails.logger.warn "YCloud: Business account deleted: #{waba&.dig(:id)}"
    store_event_in_channel_config('business_account_deleted', {
                                   waba_id: waba&.dig(:id),
                                   timestamp: Time.zone.now.iso8601
                                 })
  end

  # --- Phone Number events ---

  def handle_phone_number_deleted
    phone = params[:whatsappPhoneNumber]
    Rails.logger.warn "YCloud: Phone number deleted: #{phone&.dig(:phoneNumber)}"
    store_event_in_channel_config('phone_number_deleted', {
                                   phone_number: phone&.dig(:phoneNumber),
                                   timestamp: Time.zone.now.iso8601
                                 })
  end

  def handle_phone_number_name_updated
    phone = params[:whatsappPhoneNumber]
    return if phone.blank?

    Rails.logger.info "YCloud: Phone number display name updated: #{phone[:displayName]}, status: #{phone[:nameStatus]}"
    store_event_in_channel_config('phone_number_name_update', {
                                   display_name: phone[:displayName],
                                   name_status: phone[:nameStatus],
                                   timestamp: Time.zone.now.iso8601
                                 })
  end

  def handle_phone_number_quality_updated
    phone = params[:whatsappPhoneNumber]
    return if phone.blank?

    Rails.logger.info "YCloud: Phone number quality updated: #{phone[:qualityRating]}"
    store_event_in_channel_config('phone_number_quality_update', {
                                   quality_rating: phone[:qualityRating],
                                   messaging_limit: phone[:messagingLimit],
                                   timestamp: Time.zone.now.iso8601
                                 })
  end

  # --- Payment event ---

  def handle_payment_updated
    payment = params[:whatsappPayment]
    return if payment.blank?

    Rails.logger.info "YCloud: Payment update for #{payment[:referenceId]}: status=#{payment[:status]}"
    store_event_in_channel_config('payment_update', {
                                   reference_id: payment[:referenceId],
                                   status: payment[:status],
                                   amount: payment[:amount],
                                   currency: payment[:currency],
                                   timestamp: Time.zone.now.iso8601
                                 })
  end

  # --- Call events ---

  def handle_call_event
    call = params[:whatsappCall]
    return if call.blank?

    Rails.logger.info "YCloud: Call event #{params[:type]} for call #{call[:id]}, status: #{call[:status]}"
    store_event_in_channel_config('call_event', {
                                   call_id: call[:id],
                                   event: params[:type],
                                   status: call[:status],
                                   from: call[:from],
                                   to: call[:to],
                                   timestamp: Time.zone.now.iso8601
                                 })
  end

  # --- Flow event ---

  def handle_flow_status_change
    flow = params[:whatsappFlow]
    return if flow.blank?

    Rails.logger.info "YCloud: Flow #{flow[:id]} status changed to: #{flow[:status]}"
    store_event_in_channel_config('flow_status_change', {
                                   flow_id: flow[:id],
                                   status: flow[:status],
                                   timestamp: Time.zone.now.iso8601
                                 })
  end

  # --- User Preferences (marketing opt-in/opt-out) ---

  def handle_user_preferences
    preferences = params[:whatsappUserPreferences]
    return if preferences.blank?

    Rails.logger.info "YCloud: User preferences update: #{preferences[:waId]} opted_in=#{preferences[:optedIn]}"

    # Update Chatwoot contact subscription preference if contact exists
    contact = find_contact_by_phone(preferences[:waId])
    return unless contact

    contact.update(
      custom_attributes: contact.custom_attributes.merge(
        'whatsapp_opted_in' => preferences[:optedIn],
        'whatsapp_opt_update_at' => Time.zone.now.iso8601
      )
    )
  end

  # --- SMB (Small/Medium Business) events ---

  # SMB history: Messages sent from the native WhatsApp Business app.
  # We can ingest these as outgoing messages to keep Chatwoot in sync.
  def handle_smb_history
    inbound = params[:whatsappInboundMessage]
    return {} if inbound.blank?

    # These are outgoing messages sent from the WhatsApp Business app
    # We transform them so they appear in the conversation history
    {
      contacts: [{
        profile: { name: inbound.dig(:customerProfile, :name) || inbound[:to] },
        wa_id: inbound[:to]
      }],
      messages: [build_message_from_inbound(inbound)]
    }
  end

  def handle_smb_message_echo
    echo = params[:whatsappMessage]
    return if echo.blank?

    Rails.logger.info "YCloud: SMB message echo for #{echo[:id]}, status: #{echo[:status]}"
  end

  def handle_smb_app_state_sync
    Rails.logger.info 'YCloud: SMB app state sync event received'
  end

  # --- YCloud Contact CRM events ---

  def handle_ycloud_contact_event
    contact_data = params[:contact]
    return if contact_data.blank?

    Rails.logger.info "YCloud: Contact #{params[:type]} event for #{contact_data[:id]}"
  end

  # --- Unsubscribe events ---

  def handle_unsubscribe_event
    unsub = params[:unsubscriber]
    return if unsub.blank?

    Rails.logger.info "YCloud: Unsubscribe #{params[:type]} for #{unsub[:customer]} on #{unsub[:channel]}"

    contact = find_contact_by_phone(unsub[:customer])
    return unless contact

    opted_out = params[:type] == 'contact.unsubscribe.created'
    contact.update(
      custom_attributes: contact.custom_attributes.merge(
        "whatsapp_unsubscribed_#{unsub[:channel]}" => opted_out,
        'whatsapp_unsub_update_at' => Time.zone.now.iso8601
      )
    )
  end

  # --- Helpers ---

  def download_attachment_file(attachment_payload)
    url = attachment_payload[:link] || inbox.channel.media_url(attachment_payload[:id])
    response = HTTParty.head(url, headers: inbox.channel.api_headers)
    inbox.channel.authorization_error! if response.unauthorized? || response.forbidden?
    return unless response.success?

    Down.download(url, headers: inbox.channel.api_headers)
  end

  def sync_templates_async
    # Schedule a template sync to pick up changes from YCloud
    channel = inbox.channel
    channel.sync_templates if channel.respond_to?(:sync_templates)
  rescue StandardError => e
    Rails.logger.error "YCloud: Failed to sync templates after webhook: #{e.message}"
  end

  def store_event_in_channel_config(event_key, event_data)
    channel = inbox.channel
    config = channel.provider_config.dup
    config['last_events'] ||= {}
    config['last_events'][event_key] = event_data
    channel.update(provider_config: config)
  rescue StandardError => e
    Rails.logger.error "YCloud: Failed to store event #{event_key}: #{e.message}"
  end

  def find_contact_by_phone(phone_number)
    return if phone_number.blank?

    normalized = phone_number.start_with?('+') ? phone_number : "+#{phone_number}"
    inbox.contact_inboxes.joins(:contact).find_by(contacts: { phone_number: normalized })&.contact
  end
end
