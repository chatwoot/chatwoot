class ConversationPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    # FIXME: for agent bots
    return true if @user.blank?

    record.members_with_access.include? Current.user
  end
end
