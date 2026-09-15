class WechatKf::IncomingMessageService
  def initialize(channel)
    @channel = channel
  end

  def perform(entry)
    return handle_delivery_failure(entry) if entry['msgtype'] == 'event' && entry.dig('event', 'event_type') == 'msg_send_fail'
    return unless entry['msgtype'] == 'text' && entry['origin'] == 3

    inbox = @channel.inbox
    message_id = entry.fetch('msgid')
    return if inbox.messages.exists?(source_id: message_id)

    contact_inbox = find_or_create_contact_inbox(inbox, entry.fetch('external_userid'))
    conversation = find_or_create_conversation(inbox, contact_inbox)
    conversation.messages.create!(
      account_id: inbox.account_id, inbox_id: inbox.id, sender: contact_inbox.contact,
      content: entry.fetch('text').fetch('content'), message_type: :incoming, source_id: message_id,
      created_at: Time.zone.at(entry.fetch('send_time'))
    )
  end

  private

  def find_or_create_contact_inbox(inbox, external_userid)
    ContactInboxWithContactBuilder.new(
      inbox: inbox, source_id: external_userid,
      contact_attributes: { name: external_userid, identifier: "wechat_kf:#{@channel.wechat_kf_integration.corp_id}:#{external_userid}" }
    ).perform
  end

  def find_or_create_conversation(inbox, contact_inbox)
    conversations = contact_inbox.conversations
    conversation = if inbox.lock_to_single_conversation
                     conversations.last
                   else
                     conversations.where.not(status: :resolved).last
                   end
    conversation || Conversation.create!(
      account_id: inbox.account_id, inbox_id: inbox.id,
      contact_id: contact_inbox.contact_id, contact_inbox_id: contact_inbox.id
    )
  end

  def handle_delivery_failure(entry)
    failed_id = entry.dig('event', 'fail_msgid')
    message = @channel.inbox.messages.find_by(source_id: failed_id)
    if message.nil? && failed_id.to_s.start_with?('cw_')
      raise CustomExceptions::WechatKfApiError, "WeChat Customer Service outgoing message #{failed_id} is not yet saved"
    end
    return unless message

    Messages::StatusUpdateService.new(message, 'failed',
                                      I18n.t('errors.wechat_kf.delivery_failed', code: entry.dig('event', 'fail_type'))).perform
  end
end
