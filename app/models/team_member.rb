# == Schema Information
#
# Table name: team_members
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  team_id    :bigint           not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_team_members_on_team_id              (team_id)
#  index_team_members_on_team_id_and_user_id  (team_id,user_id) UNIQUE
#  index_team_members_on_user_id              (user_id)
#
class TeamMember < ApplicationRecord
  belongs_to :user
  belongs_to :team
  validates :user_id, uniqueness: { scope: :team_id }

  after_create :add_agent_to_round_robin
  after_destroy :remove_agent_from_round_robin

  private

  def add_agent_to_round_robin
    team.inboxes.each do |inbox|
      inbox_id = inbox.id
      inbox_by_id = Inbox.find(inbox_id)
      ::AutoAssignment::InboxRoundRobinService.new(inbox: inbox_by_id).add_agent_to_queue(user_id)
    end
  end

  def remove_agent_from_round_robin
    team.inboxes.each do |inbox|
      inbox_id = inbox.id
      inbox_by_id = Inbox.find(inbox_id)
      ::AutoAssignment::InboxRoundRobinService.new(inbox: inbox_by_id).remove_agent_from_queue(user_id)
    end
  end
end

TeamMember.include_mod_with('Audit::TeamMember')
