class InternalChatListener < BaseListener
  include Events::Types

  def internal_chat_message_created(event)
    message = event.data[:message]
    channel = message.channel
    account = message.account
    tokens = member_tokens(channel)

    unhide_dm_members(channel) if channel.channel_type_dm?
    broadcast(account, tokens, INTERNAL_CHAT_MESSAGE_CREATED, message_event_data(message))
    broadcast_typing_off(account, channel, message.sender)
  end

  def internal_chat_message_updated(event)
    message = event.data[:message]
    channel = message.channel
    account = message.account
    tokens = member_tokens(channel)

    broadcast(account, tokens, INTERNAL_CHAT_MESSAGE_UPDATED, message_event_data(message))
  end

  def internal_chat_message_deleted(event)
    message_data = event.data[:message_data]
    account = Account.find_by(id: message_data[:account_id])
    channel = InternalChat::Channel.find_by(id: message_data[:internal_chat_channel_id])
    return if account.blank? || channel.blank?
    return unless channel.account_id == account.id

    tokens = member_tokens(channel)
    broadcast(account, tokens, INTERNAL_CHAT_MESSAGE_DELETED, message_data)
  end

  def internal_chat_channel_updated(event)
    channel = event.data[:channel]
    account = channel.account
    # Use pre-captured tokens when available (e.g. after channel destroy)
    tokens = event.data[:member_tokens] || member_tokens(channel)

    broadcast(account, tokens, INTERNAL_CHAT_CHANNEL_UPDATED,
              {
                id: channel.id,
                name: channel.name,
                description: channel.description,
                channel_type: channel.channel_type,
                status: channel.status,
                category_id: channel.category_id,
                last_activity_at: channel.last_activity_at,
                member_user_ids: channel.channel_members.pluck(:user_id)
              })
  end

  def internal_chat_typing_on(event)
    channel = event.data[:channel]
    user = event.data[:user]
    account = channel.account
    tokens = member_tokens(channel, exclude_user: user)

    broadcast(account, tokens, INTERNAL_CHAT_TYPING_ON, { channel: { id: channel.id }, user: user.push_event_data })
  end

  def internal_chat_typing_off(event)
    channel = event.data[:channel]
    user = event.data[:user]
    account = channel.account
    tokens = member_tokens(channel, exclude_user: user)

    broadcast(account, tokens, INTERNAL_CHAT_TYPING_OFF, { channel: { id: channel.id }, user: user.push_event_data })
  end

  def internal_chat_poll_voted(event)
    poll = event.data[:poll]
    message = event.data[:message]
    channel = message.channel
    account = message.account
    tokens = member_tokens(channel)

    broadcast(account, tokens, INTERNAL_CHAT_POLL_VOTED,
              poll_event_data(poll).merge(internal_chat_channel_id: channel.id))
  end

  def internal_chat_reaction_created(event)
    reaction = event.data[:reaction]
    message = reaction.message
    channel = message.channel
    account = message.account
    tokens = member_tokens(channel)

    broadcast(account, tokens, INTERNAL_CHAT_REACTION_CREATED, reaction_event_data(reaction))
  end

  def internal_chat_reaction_deleted(event)
    reaction_data = event.data[:reaction_data]
    account = Account.find_by(id: reaction_data[:account_id])
    channel = InternalChat::Channel.find_by(id: reaction_data[:internal_chat_channel_id])
    return if account.blank? || channel.blank?
    return unless channel.account_id == account.id

    tokens = member_tokens(channel)
    broadcast(account, tokens, INTERNAL_CHAT_REACTION_DELETED, reaction_data)
  end

  private

  def broadcast_typing_off(account, channel, user)
    tokens = member_tokens(channel, exclude_user: user)
    broadcast(account, tokens, INTERNAL_CHAT_TYPING_OFF, { channel: { id: channel.id }, user: user.push_event_data })
  end

  def unhide_dm_members(channel)
    channel.channel_members.where(hidden: true).find_each { |m| m.update(hidden: false) }
  end

  def member_tokens(channel, exclude_user: nil)
    users = if channel.channel_type_public_channel?
              channel.account.users
            else
              channel.members
            end

    tokens = users.pluck(:pubsub_token)
    tokens -= [exclude_user.pubsub_token] if exclude_user.present?
    tokens
  end

  def message_event_data(message)
    data = base_message_data(message)
    data[:poll] = poll_event_data(message.poll) if message.poll.present?
    data
  end

  def base_message_data(message)
    {
      id: message.id, content: message.content, content_type: message.content_type,
      content_attributes: message.content_attributes, internal_chat_channel_id: message.internal_chat_channel_id,
      sender: message.sender.push_event_data, parent_id: message.parent_id, echo_id: message.echo_id,
      replies_count: message.replies_count, created_at: message.created_at, updated_at: message.updated_at,
      reactions: message.reactions.includes(:user).map { |r| { id: r.id, emoji: r.emoji, user_id: r.user_id, user: { name: r.user&.name } } },
      attachments: message.attachments.map { |a| attachment_event_data(a) }
    }
  end

  def poll_event_data(poll)
    {
      id: poll.id,
      question: poll.question,
      multiple_choice: poll.multiple_choice,
      public_results: poll.public_results,
      allow_revote: poll.allow_revote,
      expires_at: poll.expires_at,
      internal_chat_message_id: poll.internal_chat_message_id,
      options: poll.options.ordered.includes(votes: :user).map { |option| poll_option_event_data(option, poll) },
      total_votes: poll.total_votes_count,
      created_at: poll.created_at,
      updated_at: poll.updated_at
    }
  end

  def poll_option_event_data(option, poll)
    data = {
      id: option.id,
      text: option.text,
      emoji: option.emoji,
      image_url: option.image_url,
      position: option.position,
      votes_count: option.votes_count
    }
    data[:voters] = option.votes.map { |v| v.user.push_event_data } if poll.public_results
    data
  end

  def attachment_event_data(attachment)
    {
      id: attachment.id,
      file_type: attachment.file_type,
      external_url: attachment.external_url,
      extension: attachment.extension,
      file_url: attachment.file.attached? ? Rails.application.routes.url_helpers.url_for(attachment.file) : nil
    }
  end

  def reaction_event_data(reaction)
    {
      id: reaction.id,
      emoji: reaction.emoji,
      user_id: reaction.user_id,
      user: { name: reaction.user.name },
      message_id: reaction.internal_chat_message_id,
      internal_chat_channel_id: reaction.message.internal_chat_channel_id,
      created_at: reaction.created_at
    }
  end

  # Every internal chat delivery goes through here, including the token lists the controllers capture
  # before a destroy, so this is where recipients without internal chat access are dropped.
  def broadcast(account, tokens, event_name, data)
    return if tokens.blank?

    tokens = FeatureAccess.new(account).users_with('internal_chat.access').where(pubsub_token: tokens.uniq).pluck(:pubsub_token)
    return if tokens.empty?

    payload = data.merge(account_id: account.id)
    ::ActionCableBroadcastJob.perform_later(tokens, event_name, payload)
  end
end
