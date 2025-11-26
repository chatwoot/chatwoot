class Voice::Conference::EndService
  pattr_initialize [:conversation!]

  def perform
    return if credentials_blank?

    conferences_in_progress.each { |conf| complete_conference(conf) }
  rescue StandardError => e
    log_end_error(e)
  end

  private

  def credentials_blank?
    account_sid.blank? || auth_token.blank?
  end

  def conferences_in_progress
    twilio_client.conferences.list(
      friendly_name: Voice::Conference::Name.for(conversation),
      status: 'in-progress'
    )
  end

  def complete_conference(conf)
    twilio_client.conferences(conf.sid).update(status: 'completed')
  rescue StandardError => e
    Rails.logger.error(
      "VOICE_CONFERENCE_END_UPDATE_ERROR conf=#{conf.sid} error=#{e.class}: #{e.message}"
    )
  end

  def log_end_error(error)
    Rails.logger.error(
      "VOICE_CONFERENCE_END_ERROR account=#{conversation.account_id} conversation=#{conversation.display_id} " \
      "error=#{error.class}: #{error.message}"
    )
  end

  def twilio_client
    @twilio_client ||= ::Twilio::REST::Client.new(account_sid, auth_token)
  end

  def account_sid
    @account_sid ||= conversation.inbox.channel.provider_config_hash['account_sid']
  end

  def auth_token
    @auth_token ||= conversation.inbox.channel.provider_config_hash['auth_token']
  end
end
