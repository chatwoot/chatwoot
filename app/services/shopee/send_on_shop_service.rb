class Shopee::SendOnShopService < Base::SendOnChannelService

  private

  def channel_class
    Channel::Shopee
  end

  def perform_reply
    send_text_message if message.content.present?
    send_card_message if message.shopee_card?
    send_attachment_files if message.attachments.present?
    Messages::StatusUpdateService.new(message, 'delivered').perform
  rescue Integrations::Shopee::Error => e
    handle_error(e)
    Messages::StatusUpdateService.new(message, 'failed', e.response.parsed_response['message']).perform
    Rails.logger.info "Shopee::SendOnShopService: Error sending message to Shopee : Shop - #{channel.shop_id} : #{e.message}"
  end

  def message_caller
    @message_caller ||= Integrations::Shopee::Message.new(shop_id: channel.shop_id, access_token: channel.access_token)
  end

  def user_id
    @user_id ||= contact.identifier.to_i
  end

  def conversation_code
    @conversation_code ||= contact_inbox.source_id.to_i
  end

  def send_text_message
    response = message_caller.send_text(user_id, conversation_code, message.content)
    message.update!(source_id: response['message_id']) if message.source_id.blank? && response['message_id'].present?
  end

  def send_card_message
    shopee_data = message.content_attributes.dig('original') || {}
    if shopee_data['voucher_id'].present?
      response = message_caller.send_voucher(user_id, conversation_code, shopee_data['voucher_id'], shopee_data['voucher_code'])
    elsif shopee_data['order_sn'].present?
      response = message_caller.send_order(user_id, conversation_code, shopee_data['order_sn'])
    elsif shopee_data['item_id'].present?
      response = message_caller.send_item(user_id, conversation_code, shopee_data['item_id'])
    elsif shopee_data['item_ids'].present?
      shopee_data['item_ids'].to_a.each do |item_id|
        response = message_caller.send_item(user_id, conversation_code, item_id)
      end
    else
      return
    end

    message.update!(source_id: message.source_id.presence || response['message_id'].presence)
  end

  def send_attachment_files
    message.attachments.each do |attachment|
      case attachment.file_type
      when 'video'
        message_caller.send_video(user_id, conversation_code, attachment.download_url)
      when 'image'
        message_caller.send_image(user_id, conversation_code, attachment.download_url)
      end
    end
  end

  def handle_error(exception)
    if exception.response.code == 403 # Invalid access_token
      channel.authorization_error!
      channel.refresh_access_token!
    end
  end
end
