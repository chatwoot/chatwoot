class Voice::Conference::EndService
  pattr_initialize [:conversation!]

  def perform
    client = twilio_client
    return unless client

    client.conferences.list(friendly_name: conference_name, status: 'in-progress').each do |conf|
      client.conferences(conf.sid).update(status: 'completed')
    rescue StandardError => e
      log_update_error(conf.sid, e)
    end
  rescue StandardError => e
    log_end_error(e)
  end

  private

  def twilio_client
    config = conversation.inbox.channel.provider_config_hash
    account_sid = config['account_sid']
    auth_token = config['auth_token']
    return if account_sid.blank? || auth_token.blank?

    ::Twilio::REST::Client.new(account_sid, auth_token)
  end

  def conference_name
    @conference_name ||= Voice::Conference::Name.for(conversation)
  end

  def log_update_error(conference_sid, error)
    Rails.logger.error(
      "VOICE_CONFERENCE_END_UPDATE_ERROR conf=#{conference_sid} error=#{error.class}: #{error.message}"
    )
  end

  def log_end_error(error)
    Rails.logger.error(
      "VOICE_CONFERENCE_END_ERROR account=#{conversation.account_id} conversation=#{conversation.display_id} " \
      "name=#{conference_name} error=#{error.class}: #{error.message}"
    )
  end
end
