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
    move_resolution(predecessor)
    move_handoff(predecessor)

    response = CsatSurveyResponse.find_by(conversation_id: conversation.id)
    [predecessor, episode].each do |affected|
      recount_captain_replies(affected)
      recount_human_reply(affected)
      reattribute_csat(affected, response)
      affected.save! if affected.changed?
    end
  end

  def move_resolution(source)
    return if source.resolved_at.blank?

    target = attributed_episode(source.resolved_at)
    return if target == source

    target.update!(resolved_at: latest(target.resolved_at, source.resolved_at))
    source.update!(resolved_at: nil)
  end

  def move_handoff(source)
    return if source.handoff_at.blank?

    target = attributed_episode(source.handoff_at)
    return if target == source

    if target.handoff_at.blank? || source.handoff_at < target.handoff_at
      target.update!(handoff_at: source.handoff_at, handoff_reason_category: source.handoff_reason_category)
    end
    source.update!(handoff_at: nil, handoff_reason_category: nil)
  end

  def reattribute_csat(episode, response)
    if response && attributed_episode(response.message.created_at) == episode
      episode.csat_rating = response.rating
      episode.csat_received_at = response.created_at
    else
      episode.csat_rating = nil
      episode.csat_received_at = nil
    end
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

  def public_human_reply?(message)
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
