class Integrations::Shopee::Message < Integrations::Shopee::Base
  MAX_PAGE_SIZE = 60
  BUSINESS_TYPE = 0 # 0: For seller buyer, 11: For seller affiliate

  def list(conversation_id)
    payload = {
      conversation_id: conversation_id,
      page_size: MAX_PAGE_SIZE
    }
    auth_client
      .query(payload)
      .get('/api/v2/sellerchat/get_message')
  end

  def send_text(user_id, conversation_id, message)
    send_message({
                   business_type: BUSINESS_TYPE,
                   to_id: user_id,
                   conversation_id: conversation_id,
                   message_type: :text,
                   content: { text: message }
                 })
  end

  def send_image(user_id, conversation_id, image_url)
    image = file_uploader.upload_image(image_url)
    send_message({
                   business_type: BUSINESS_TYPE,
                   to_id: user_id,
                   conversation_id: conversation_id,
                   message_type: :image,
                   content: { image_url: image }
                 })
  end

  def send_order(user_id, conversation_id, order_number)
    send_message({
                   business_type: BUSINESS_TYPE,
                   to_id: user_id,
                   conversation_id: conversation_id,
                   message_type: :order,
                   content: { order_sn: order_number }
                 })
  end

  def send_video(user_id, conversation_id, video_url)
    video_info = file_uploader.upload_video(video_url)
    send_message({
                   business_type: BUSINESS_TYPE,
                   to_id: user_id,
                   conversation_id: conversation_id,
                   message_type: :video,
                   content: video_info
                 })
  end

  def send_voucher(user_id, conversation_id, voucher_id, voucher_code)
    send_message({
                   business_type: BUSINESS_TYPE,
                   to_id: user_id,
                   conversation_id: conversation_id,
                   message_type: :voucher,
                   content: { voucher_id: voucher_id, voucher_code: voucher_code }
                 })
  end

  def send_item(user_id, conversation_id, item_id)
    send_message({
                   business_type: BUSINESS_TYPE,
                   to_id: user_id,
                   conversation_id: conversation_id,
                   message_type: :item,
                   content: { item_id: item_id.to_i }
                 })
  end

  private

  def send_message(payload)
    auth_client
      .body(payload)
      .post('/api/v2/sellerchat/send_message')
      .dig('response')
  end

  def file_uploader
    @file_uploader ||= Integrations::Shopee::Uploader.new(shop_id: shop_id, access_token: access_token)
  end
end
