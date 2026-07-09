class Crm::Cards::Broadcaster
  include Events::Types

  EVENTS = [
    CRM_CARD_CREATED,
    CRM_CARD_UPDATED,
    CRM_CARD_MOVED,
    CRM_CARD_ARCHIVED
  ].freeze

  def self.broadcast(card, event_name)
    new(card, event_name).perform
  end

  def self.recipient_users_for(card)
    new(card, CRM_CARD_UPDATED).send(:recipient_users)
  end

  def initialize(card, event_name)
    @card = card
    @event_name = event_name
  end

  def perform
    return unless Crm::Config.enabled?
    return unless EVENTS.include?(@event_name)

    recipient_users.each do |user|
      next if user.pubsub_token.blank?

      ActionCableBroadcastJob.perform_later([user.pubsub_token], @event_name, payload_for(user))
    end
  end

  private

  def payload_for(user)
    Crm::Cards::PayloadBuilder.new(
      card_with_associations,
      user: user,
      account_user: account_user_for(user)
    ).perform.tap do |data|
      data[:account_id] = @card.account_id
      data[:performer] = Current.user&.push_event_data if Current.user.present?
    end
  end

  def card_with_associations
    @card_with_associations ||= Crm::Card
                                .includes(
                                  { contact: { label_taggings: :tag } },
                                  :owner,
                                  :pipeline,
                                  :stage,
                                  { inbox: { agent_bot_inbox: :agent_bot } },
                                  { primary_conversation: [:conversation_participants, :assignee, { inbox: { agent_bot_inbox: :agent_bot } }] }
                                )
                                .find(@card.id)
  end

  def account
    @account ||= @card.account
  end

  def recipient_users
    users = admin_users
    users += inbox_recipient_users if @card.inbox_id.present?
    users += standalone_owner_users if @card.inbox_id.blank?
    users.index_by(&:id).values
  end

  def admin_users
    account.administrators.to_a
  end

  def inbox_recipient_users
    return assigned_only_users if inbox_setting&.assigned_only?

    @card.inbox.members.to_a
  end

  def assigned_only_users
    user_ids = [card_with_associations.owner_id]
    user_ids << primary_conversation&.assignee_id
    user_ids += primary_conversation_participant_user_ids

    account.users.where(id: user_ids.compact.uniq).where(id: inbox_member_ids).to_a
  end

  def inbox_member_ids
    @inbox_member_ids ||= @card.inbox.members.select(:id)
  end

  def standalone_owner_users
    return [] if @card.owner_id.blank?

    account.users.where(id: @card.owner_id).to_a
  end

  def primary_conversation
    card_with_associations.primary_conversation
  end

  def primary_conversation_participant_user_ids
    return [] if primary_conversation.blank?

    primary_conversation.conversation_participants.map(&:user_id)
  end

  def inbox_setting
    return @inbox_setting if defined?(@inbox_setting)

    @inbox_setting = Crm::InboxSetting.find_by(
      account_id: @card.account_id,
      inbox_id: @card.inbox_id
    )
  end

  def account_user_for(user)
    account_users_by_user_id[user.id]
  end

  def account_users_by_user_id
    @account_users_by_user_id ||= account.account_users.where(user_id: recipient_users.map(&:id)).index_by(&:user_id)
  end
end
