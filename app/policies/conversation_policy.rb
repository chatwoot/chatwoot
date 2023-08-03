class ConversationPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    record.members_with_access.include? Current.user
  end
end
