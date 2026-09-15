class Webhooks::WechatKfController < ActionController::API
  def verify
    integration = WechatKfIntegration.find_by(corp_id: params[:corp_id])
    return head :not_found unless integration

    render plain: crypt_service(integration).decrypt(
      encrypted: params[:echostr], signature: params[:msg_signature], timestamp: params[:timestamp], nonce: params[:nonce]
    )
  rescue WechatKf::CallbackCryptService::InvalidCallback
    head :unauthorized
  end

  def process_payload
    integration = WechatKfIntegration.find_by(corp_id: params[:corp_id])
    return head :not_found unless integration

    event = decoded_event(integration)
    return head :unprocessable_entity unless event
    return head :ok unless event[:type] == 'event' && event[:name] == 'kf_msg_or_event'

    enqueue_kf_event(integration, event)
  rescue WechatKf::CallbackCryptService::InvalidCallback
    head :unauthorized
  end

  private

  def enqueue_kf_event(integration, event)
    return head :unprocessable_entity if event[:token].blank?
    return head :ok unless integration.channels.exists?(open_kfid: event[:open_kfid])

    WechatKf::SyncMessagesJob.perform_later(integration.id, event[:open_kfid], event[:token], Time.current.to_i)
    head :ok
  end

  def decoded_event(integration)
    encrypted = Nokogiri::XML(request.raw_post, &:nonet).at_xpath('/xml/Encrypt')&.text
    return if encrypted.blank?

    plaintext = crypt_service(integration).decrypt(
      encrypted: encrypted, signature: params[:msg_signature], timestamp: params[:timestamp], nonce: params[:nonce]
    )
    document = Nokogiri::XML(plaintext, &:nonet)
    {
      type: document.at_xpath('/xml/MsgType')&.text,
      name: document.at_xpath('/xml/Event')&.text,
      open_kfid: document.at_xpath('/xml/OpenKfId')&.text,
      token: document.at_xpath('/xml/Token')&.text
    }
  end

  def crypt_service(integration)
    WechatKf::CallbackCryptService.new(integration)
  end
end
