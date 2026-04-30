class Voice::Provider::Twilio::ConferenceService
  pattr_initialize [:call!]

  def ensure_conference_sid
    return call.conference_sid if call.conference_sid.present?

    call.update!(conference_sid: call.default_conference_sid)
    call.conference_sid
  end

  def mark_agent_joined(user:)
    call.update!(accepted_by_agent: user)
  end

  def end_conference
    return if call.conference_sid.blank?

    client = call.inbox.channel.client
    client
      .conferences
      .list(friendly_name: call.conference_sid, status: 'in-progress')
      .each { |conf| client.conferences(conf.sid).update(status: 'completed') }
  end
end
