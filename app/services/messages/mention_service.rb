class Messages::MentionService
  pattr_initialize [:message!]

  def perform
    process_user_team_mentions
    process_contact_mentions
  end

  private

  def process_user_team_mentions
    return unless valid_user_mention_message?

    validated_mentioned_ids = filter_mentioned_ids_by_inbox
    return if validated_mentioned_ids.blank?

    Conversations::UserMentionJob.perform_later(validated_mentioned_ids, message.conversation.id, message.account.id)
    generate_notifications_for_mentions(validated_mentioned_ids)
    add_mentioned_users_as_participants(validated_mentioned_ids)
  end

  def process_contact_mentions
    contact_ids = contact_mentioned_ids
    return if contact_ids.blank?

    message.update!(content_attributes: message.content_attributes.merge('mentioned_contacts' => contact_ids))
  end

  def valid_user_mention_message?
    message.private? && message.content.present? && mentioned_ids.present?
  end

  def contact_mentioned_ids
    return [] if message.content.blank?

    message.content.scan(%r{\(mention://contact/(\d+)/(.+?)\)}).map(&:first).uniq
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
