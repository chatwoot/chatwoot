class Voice::Provider::Twilio::ConferenceService
  pattr_initialize [:conversation!, { twilio_client: nil }]

  def ensure_conference_sid
    existing = conversation.additional_attributes&.dig('conference_sid')
    return existing if existing.present?

    sid = Voice::Conference::Name.for(conversation)
    merge_attributes('conference_sid' => sid)
    sid
  end

  def mark_agent_joined(user:)
    merge_attributes(
      'agent_joined' => true,
      'joined_at' => Time.current.to_i,
      'joined_by' => { id: user.id, name: user.name }
    )
  end

  def end_conference
    twilio_client
      .conferences
      .list(friendly_name: Voice::Conference::Name.for(conversation), status: 'in-progress')
      .each { |conf| twilio_client.conferences(conf.sid).update(status: 'completed') }
  end

  private

  def merge_attributes(attrs)
    current = conversation.additional_attributes || {}
    conversation.update!(additional_attributes: current.merge(attrs))
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
