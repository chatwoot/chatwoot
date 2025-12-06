class Voice::Conference::EndService
  pattr_initialize [:conversation!]

  def perform
    conferences_in_progress.each { |conf| complete_conference(conf) }
  end

  private

  def conferences_in_progress
    twilio_client.conferences.list(
      friendly_name: Voice::Conference::Name.for(conversation),
      status: 'in-progress'
    )
  end

  def complete_conference(conf)
    twilio_client.conferences(conf.sid).update(status: 'completed')
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
