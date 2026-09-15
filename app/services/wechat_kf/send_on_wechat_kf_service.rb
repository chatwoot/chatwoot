class WechatKf::SendOnWechatKfService < Base::SendOnChannelService
  private

  def channel_class
    Channel::WechatKf
  end

  def perform_reply
    content = message.outgoing_content
    unless supported_reply?(content)
      Messages::StatusUpdateService.new(message, 'failed', I18n.t('errors.wechat_kf.unsupported_reply')).perform
      return
    end

    message.update!(source_id: send_text(content).fetch('msgid'))
  rescue CustomExceptions::WechatKfApiError => e
    Messages::StatusUpdateService.new(message, 'failed', e.message).perform
  end

  def supported_reply?(content)
    conversation.can_reply? && message.attachments.none? && content.present? && content.bytesize <= 2048
  end

  def send_text(content)
    WechatKf::ApiClient.new(channel.wechat_kf_integration).send_text(
      open_kfid: channel.open_kfid, external_userid: contact_inbox.source_id,
      content: content, msgid: "cw_#{message.id}"
    )
  end
end
