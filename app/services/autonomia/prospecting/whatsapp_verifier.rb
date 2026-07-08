class Autonomia::Prospecting::WhatsappVerifier
  Result = Struct.new(:lead, :exists, :phone, :chat_id, keyword_init: true)

  Error = Class.new(StandardError)

  def initialize(lead:)
    @lead = lead
    @account = lead.account
  end

  def perform
    raise Error, 'prospecting.whatsapp.phone_missing' if normalized_phone.blank?
    raise Error, 'prospecting.whatsapp.waha_not_configured' unless Waha::Config.enabled?
    raise Error, 'prospecting.whatsapp.session_missing' if waha_session.blank?

    response = Waha::Client.new.check_contact_exists(phone: normalized_phone, session: waha_session)
    exists = ActiveModel::Type::Boolean.new.cast(response['numberExists'])
    chat_id = exists ? response['chatId'].presence || "#{normalized_phone.delete('+')}@c.us" : nil

    persist_result!(exists: exists, chat_id: chat_id)

    Result.new(lead: @lead.reload, exists: exists, phone: normalized_phone, chat_id: chat_id)
  rescue Waha::Client::Error => e
    persist_failure!(e.message)
    raise Error, 'prospecting.whatsapp.verification_failed'
  end

  private

  def normalized_phone
    @normalized_phone ||= begin
      raw = @lead.phone.to_s.strip
      digits = raw.gsub(/\D/, '')
      if digits.blank?
        nil
      else
        phone =
          if raw.start_with?('+')
            "+#{digits}"
          elsif digits.start_with?('55')
            "+#{digits}"
          elsif digits.length.in?([10, 11])
            "+55#{digits}"
          else
            "+#{digits}"
          end

        phone.match?(/\A\+[1-9]\d{7,14}\z/) ? phone : nil
      end
    end
  end

  def waha_session
    @waha_session ||= begin
      inbox = @account.inboxes.where(channel_type: 'Channel::Api').includes(:channel).find do |item|
        attrs = item.channel.additional_attributes.to_h
        attrs['provider'] == 'waha' && attrs['session'].present?
      end

      inbox&.channel&.additional_attributes.to_h['session']
    end
  end

  def persist_result!(exists:, chat_id:)
    payload = {
      'status' => exists ? 'verified' : 'not_whatsapp',
      'phone' => normalized_phone,
      'chat_id' => chat_id,
      'session' => waha_session,
      'checked_at' => Time.current.iso8601
    }.compact

    @lead.update!(metadata: @lead.metadata.to_h.merge('whatsapp_verification' => payload))
  end

  def persist_failure!(message)
    payload = {
      'status' => 'failed',
      'phone' => normalized_phone,
      'session' => waha_session,
      'error' => message.to_s.truncate(300),
      'checked_at' => Time.current.iso8601
    }.compact

    @lead.update!(metadata: @lead.metadata.to_h.merge('whatsapp_verification' => payload))
  rescue ActiveRecord::RecordInvalid
    nil
  end
end
