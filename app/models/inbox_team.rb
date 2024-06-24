# == Schema Information
#
# Table name: inbox_teams
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  inbox_id   :integer          not null
#  team_id    :integer          not null
#
# Indexes
#
#  index_inbox_teams_on_inbox_id              (inbox_id)
#  index_inbox_teams_on_inbox_id_and_team_id  (inbox_id,team_id) UNIQUE
#

class InboxTeam < ApplicationRecord
  validates :inbox_id, presence: true
  validates :team_id, presence: true
  validates :team_id, uniqueness: { scope: :inbox_id }

  belongs_to :inbox
  belongs_to :team

  after_create :add_agents_to_round_robin
  after_destroy :remove_agents_from_round_robin

  private

  def add_agents_to_round_robin
    inbox_round_robin_service = ::AutoAssignment::InboxRoundRobinService.new(inbox: inbox)
    team.members.each do |user|
      inbox_round_robin_service.add_agent_to_queue(user.id)
    end
  end

  def remove_agents_from_round_robin
    inbox_round_robin_service = ::AutoAssignment::InboxRoundRobinService.new(inbox: inbox)
    team.members.each do |user|
      inbox_round_robin_service.remove_agent_from_queue(user.id) if inbox.present?
    end
  end
end
