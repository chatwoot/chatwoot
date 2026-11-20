class Whatsapp::MissedCallMessageService
  pattr_initialize [:call!]

  def perform
    return unless sendable?

    call.with_lock do
      next if call.meta&.key?('missed_call_message_id')

      message = call.conversation.messages.create!(
        account_id: call.account_id, inbox_id: call.inbox_id, message_type: :template, content: message_text,
        additional_attributes: { 'missed_call_message' => true }
      )
      call.update!(meta: (call.meta || {}).merge('missed_call_message_id' => message.id))
    end
  end

  private

  def sendable?
    call.whatsapp? && call.missed? && channel.missed_call_message_enabled? && call.conversation.can_reply?
  end

  def message_text
    channel.provider_config['missed_call_message'].presence ||
      I18n.with_locale(call.account.locale) { I18n.t('inbox.missed_call_message.default') }
  end

  def channel
    call.inbox.channel
  end
end
