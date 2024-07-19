class ConversationPolicy < ApplicationPolicy
  def index?
    user.present? && (record.assignee == user || record.team.members.include?(user))
  end
end
