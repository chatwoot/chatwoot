class InternalChat::ChannelPolicy < ApplicationPolicy
  def index?
    agent_or_admin?
  end

  def show?
    return true if administrator?
    return agent_or_admin? if record.channel_type_public_channel?

    channel_member?
  end

  def create?
    return agent_or_admin? if record.channel_type_dm?

    administrator?
  end

  def update?
    administrator? || channel_admin?
  end

  def destroy?
    administrator?
  end

  def archive?
    administrator?
  end

  def unarchive?
    administrator?
  end

  def toggle_typing_status?
    accessible?
  end

  def mark_read?
    accessible?
  end

  def mark_unread?
    accessible?
  end

  private

  def agent_or_admin?
    @account_user.present?
  end

  def administrator?
    @account_user&.administrator?
  end

  def channel_member?
    record.channel_members.exists?(user_id: @user.id)
  end

  def channel_admin?
    record.channel_members.exists?(user_id: @user.id, role: :admin)
  end

  def accessible?
    return agent_or_admin? if record.channel_type_public_channel?

    channel_member?
  end
end

InternalChat::ChannelPolicy.prepend_mod_with('InternalChat::ChannelPolicy')
