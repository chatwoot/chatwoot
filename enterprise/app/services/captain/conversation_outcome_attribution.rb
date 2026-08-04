# Message-derived attribution shared by fact recording and boundary repair in
# Captain::ConversationOutcomeTracker: episode window scoping, recounts from
# persisted messages, reply classification, and the relocation of point facts
# after a late boundary splits a window.
module Captain::ConversationOutcomeAttribution
  private

  # A fact processed before a late boundary was written into the pre-split
  # window; inserting the boundary moves the windows but not the fact. Repair
  # recounts message-derived fields for both affected rows and relocates point
  # facts into the row whose window now contains them.
  def repair_attribution(predecessor, episode)
    move_point_facts(predecessor) if predecessor
    [predecessor, episode].compact.each do |affected|
      recount_captain_replies(affected)
      recount_human_reply(affected)
      reattribute_csat(affected)
      affected.save! if affected.changed?
    end
  end

  def move_point_facts(source)
    move_resolution(source)
    move_handoff(source)
  end

  def move_resolution(source)
    return if source.resolved_at.blank? || covers?(source, source.resolved_at)

    target = episodes.covering(source.resolved_at).where.not(id: source.id).first
    target&.update!(resolved_at: latest(target.resolved_at, source.resolved_at))
    source.update!(resolved_at: nil)
  end

  def move_handoff(source)
    return if source.handoff_at.blank? || covers?(source, source.handoff_at)

    target = episodes.covering(source.handoff_at).where.not(id: source.id).first
    if target && (target.handoff_at.blank? || source.handoff_at < target.handoff_at)
      target.update!(handoff_at: source.handoff_at, handoff_reason_category: source.handoff_reason_category)
    end
    source.update!(handoff_at: nil, handoff_reason_category: nil)
  end

  def reattribute_csat(episode)
    response = CsatSurveyResponse.find_by(conversation_id: conversation.id)
    survey_at = response&.message&.created_at

    if survey_at && covers?(episode, survey_at)
      episode.csat_rating = response.rating
      episode.csat_received_at = response.created_at
    else
      episode.csat_rating = nil
      episode.csat_received_at = nil
    end
  end

  def covers?(episode, at)
    episode.started_at <= at && (episode.ended_at.nil? || episode.ended_at > at)
  end

  def recount_captain_replies(episode)
    replies = public_captain_replies_in(episode)
    episode.captain_reply_count = replies.count
    episode.first_captain_reply_at = replies.minimum(:created_at)
    episode.last_captain_reply_at = replies.maximum(:created_at)
  end

  def recount_human_reply(episode)
    candidate = window_messages(episode)
                .where(message_type: :outgoing, private: false)
                .order(:created_at)
                .detect { |message| public_human_reply?(message) }
    episode.first_human_reply_at = candidate&.created_at
  end

  def public_captain_replies_in(episode)
    window_messages(episode).where(sender_type: 'Captain::Assistant', message_type: :outgoing, private: false)
  end

  def window_messages(episode)
    scope = conversation.messages.where(created_at: episode.started_at..)
    scope = scope.where(created_at: ...episode.ended_at) if episode.ended_at
    scope
  end

  def public_captain_reply?(message)
    message.conversation_id == conversation.id &&
      message.sender_type == 'Captain::Assistant' &&
      message.outgoing? &&
      !message.private?
  end

  def public_human_reply?(message)
    return false unless message.conversation_id == conversation.id && message.outgoing? && !message.private?
    return false if message.content_attributes['automation_rule_id'].present?
    return false if message.additional_attributes['campaign_id'].present?

    message.sender.is_a?(User) || message.content_attributes['external_echo'].present?
  end

  def earliest(existing, candidate)
    [existing, candidate].compact.min
  end

  def latest(existing, candidate)
    [existing, candidate].compact.max
  end
end
