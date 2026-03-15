class Instagram::ReactionService
  pattr_initialize [:params!, :channel!]

  def perform
    return if channel.blank? || target_message.blank? || reaction.blank?
    return if duplicate_activity?

    ::Conversations::ActivityMessageJob.perform_later(target_message.conversation, activity_message_params)
  end

  private

  def target_message
    return if reaction_mid.blank?

    @target_message ||= channel.inbox.messages.find_by(source_id: reaction_mid)
  end

  def reaction
    params[:reaction] || {}
  end

  def reaction_mid
    reaction[:mid]
  end

  def sender_id
    params.dig(:sender, :id)
  end

  def action
    reaction[:action]
  end

  def reaction_label
    reaction[:emoji].presence || reaction[:reaction].presence || 'reaction'
  end

  def actor_name
    return channel.inbox.name if sender_id == channel.instagram_id

    contact = channel.inbox.contact_inboxes.find_by(source_id: sender_id)&.contact
    contact&.name.presence || 'Customer'
  end

  def target_preview
    content = target_message.content.presence || 'an earlier message'
    content.truncate_words(10)
  end

  def activity_content
    case action
    when 'react'
      "#{actor_name} reacted with #{reaction_label} to: #{target_preview}"
    when 'unreact'
      "#{actor_name} removed a reaction from: #{target_preview}"
    else
      "#{actor_name} updated a reaction on: #{target_preview}"
    end
  end

  def activity_source_id
    [
      'ig_reaction',
      reaction_mid,
      sender_id,
      params[:timestamp],
      action,
      reaction[:reaction]
    ].join(':')
  end

  def duplicate_activity?
    target_message.conversation.messages.activity.find_by(source_id: activity_source_id).present?
  end

  def activity_message_params
    {
      account_id: target_message.account_id,
      inbox_id: target_message.inbox_id,
      message_type: :activity,
      source_id: activity_source_id,
      content: activity_content,
      content_attributes: {
        data: {
          event_type: 'instagram_reaction',
          mid: reaction_mid,
          action: action,
          reaction: reaction[:reaction],
          emoji: reaction[:emoji],
          sender_id: sender_id
        }
      }
    }
  end
end
