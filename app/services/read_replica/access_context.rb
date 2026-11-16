ReadReplica::AccessContext = Data.define(
  :account_id, :user_id, :role, :custom_role_id, :permissions, :inbox_ids,
  :participant_conversation_ids, :mention_conversation_ids, :team_id
) do
  def self.build(account:, user:, account_user:, params:)
    inbox_ids = if account_user.administrator?
                  account.inboxes.pluck(:id)
                else
                  user.inboxes.where(account_id: account.id).pluck(:id)
                end
    permissions = account_user.permissions

    new(
      account_id: account.id,
      user_id: user.id,
      role: account_user.role,
      custom_role_id: account_user.custom_role_id,
      permissions: permissions.freeze,
      inbox_ids: inbox_ids.freeze,
      participant_conversation_ids: participant_conversation_ids(account, user, params, permissions).freeze,
      mention_conversation_ids: mention_conversation_ids(account, user, params).freeze,
      team_id: team_id(account, params)
    )
  end

  def conversation_ids_for(type)
    { 'mention' => mention_conversation_ids, 'participating' => participant_conversation_ids }.fetch(type, nil)
  end

  private_class_method def self.participant_conversation_ids(account, user, params, permissions)
    needs_participants = params[:conversation_type] == 'participating' || permissions.include?('conversation_participating_manage')
    return [] unless needs_participants

    ConversationParticipant.where(account_id: account.id, user_id: user.id).pluck(:conversation_id)
  end

  private_class_method def self.mention_conversation_ids(account, user, params)
    return [] unless params[:conversation_type] == 'mention'

    account.mentions.where(user: user).pluck(:conversation_id)
  end

  private_class_method def self.team_id(account, params)
    return if params[:team_id].blank?

    account.teams.find(params[:team_id]).id
  end
end
