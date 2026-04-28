class Voice::Provider::Twilio::ConferenceService
  pattr_initialize [:conversation!]

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
    client = conversation.inbox.channel.client
    client
      .conferences
      .list(friendly_name: Voice::Conference::Name.for(conversation), status: 'in-progress')
      .each { |conf| client.conferences(conf.sid).update(status: 'completed') }
  end

  private

  def merge_attributes(attrs)
    current = conversation.additional_attributes || {}
    conversation.update!(additional_attributes: current.merge(attrs))
  end
end
