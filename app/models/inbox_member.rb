# == Schema Information
#
# Table name: inbox_members
#
#  id                    :integer          not null, primary key
#  assignment_eligible   :boolean          default(TRUE), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  inbox_id              :integer          not null
#  user_id               :integer          not null
#
# Indexes
#
#  index_inbox_members_on_inbox_id              (inbox_id)
#  index_inbox_members_on_inbox_id_and_user_id  (inbox_id,user_id) UNIQUE
#

class InboxMember < ApplicationRecord
  validates :inbox_id, presence: true
  validates :user_id, presence: true
  validates :user_id, uniqueness: { scope: :inbox_id }

  belongs_to :user
  belongs_to :inbox

  scope :assignment_eligible, -> { where(assignment_eligible: true) }

  after_destroy :remove_agent_from_round_robin
  after_save :update_round_robin_queue

  private

  def update_round_robin_queue
    if assignment_eligible? && (saved_change_to_assignment_eligible? || previously_new_record?)
      add_agent_to_round_robin
    elsif !assignment_eligible? && saved_change_to_assignment_eligible?
      remove_agent_from_round_robin
    end
  end

  def add_agent_to_round_robin
    ::AutoAssignment::InboxRoundRobinService.new(inbox: inbox).add_agent_to_queue(user_id)
  end

  def remove_agent_from_round_robin
    ::AutoAssignment::InboxRoundRobinService.new(inbox: inbox).remove_agent_from_queue(user_id) if inbox.present?
  end
end

InboxMember.include_mod_with('Audit::InboxMember')
