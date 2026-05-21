class V2::Reports::OutgoingMessagesCountBuilder
  include DateRangeHelper
  attr_reader :account, :params

  def initialize(account, params)
    @account = account
    @params = params
  end

  def build
    send("build_by_#{params[:group_by]}")
  end

  private

  def base_messages
    account.messages.outgoing.unscope(:order).where(created_at: range)
  end

  def build_by_agent
    counts = base_messages
             .where(sender_type: 'User')
             .where.not(sender_id: nil)
             .group(:sender_id)
             .count

    user_names = account.users.where(id: counts.keys).index_by(&:id)

    counts.map do |user_id, count|
      user = user_names[user_id]
      { id: user_id, name: user&.name, outgoing_messages_count: count }
    end
  end

  def build_by_team
    counts = base_messages
             .joins('INNER JOIN conversations ON messages.conversation_id = conversations.id')
             .where.not(conversations: { team_id: nil })
             .group('conversations.team_id')
             .count

    team_names = account.teams.where(id: counts.keys).index_by(&:id)

    counts.map do |team_id, count|
      team = team_names[team_id]
      { id: team_id, name: team&.name, outgoing_messages_count: count }
    end
  end

  def build_by_inbox
    counts = base_messages
             .group(:inbox_id)
             .count

    inbox_names = account.inboxes.where(id: counts.keys).index_by(&:id)

    counts.map do |inbox_id, count|
      inbox = inbox_names[inbox_id]
      { id: inbox_id, name: inbox&.name, outgoing_messages_count: count }
    end
  end

  def build_by_label
    counts = base_messages
             .joins('INNER JOIN conversations ON messages.conversation_id = conversations.id')
             .joins("INNER JOIN taggings ON taggings.taggable_id = conversations.id
                     AND taggings.taggable_type = 'Conversation' AND taggings.context = 'labels'")
             .joins('INNER JOIN tags ON tags.id = taggings.tag_id')
             .group('tags.name')
             .count

    label_ids = account.labels.where(title: counts.keys).index_by(&:title)

    counts.map do |label_name, count|
      label = label_ids[label_name]
      { id: label&.id, name: label_name, outgoing_messages_count: count }
    end
  end
end
