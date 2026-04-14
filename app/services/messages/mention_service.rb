class Messages::MentionService
  pattr_initialize [:message!]

  def perform
    return unless valid_mention_message?(message)

    validated_mentioned_ids = filter_mentioned_ids_by_inbox
    return if validated_mentioned_ids.blank?

    Conversations::UserMentionJob.perform_later(validated_mentioned_ids, message.conversation.id, message.account.id)
    generate_notifications_for_mentions(validated_mentioned_ids)
    add_mentioned_users_as_participants(validated_mentioned_ids)
  end

  private

  def valid_mention_message?(message)
    message.private? && message.content.present? && mentioned_ids.present?
  end

  def mentioned_ids
    user_mentions = message.content.scan(%r{\(mention://user/(\d+)/(.+?)\)}).map(&:first)
    team_mentions = message.content.scan(%r{\(mention://team/(\d+)/(.+?)\)}).map(&:first)

    expanded_user_ids = expand_team_mentions_to_users(team_mentions)

    (user_mentions + expanded_user_ids).uniq
  end

  def expand_team_mentions_to_users(team_ids)
    return [] if team_ids.blank?

    message.inbox.account.teams
           .joins(:team_members)
           .where(id: team_ids)
           .pluck('team_members.user_id')
           .map(&:to_s)
  end

  def valid_mentionable_user_ids
    @valid_mentionable_user_ids ||= begin
      inbox = message.inbox
      inbox.account.administrators.pluck(:id) + inbox.members.pluck(:id)
    end
  end

  def filter_mentioned_ids_by_inbox
    mentioned_ids & valid_mentionable_user_ids.map(&:to_s)
  end

  def generate_notifications_for_mentions(validated_mentioned_ids)
    validated_mentioned_ids.each do |user_id|
      NotificationBuilder.new(
        notification_type: 'conversation_mention',
        user: User.find(user_id),
        account: message.account,
        primary_actor: message.conversation,
        secondary_actor: message
      ).perform
    end
  end

  def add_mentioned_users_as_participants(validated_mentioned_ids)
    validated_mentioned_ids.each do |user_id|
      message.conversation.conversation_participants.find_or_create_by(user_id: user_id)
    end
  end
end
