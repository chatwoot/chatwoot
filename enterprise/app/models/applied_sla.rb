# == Schema Information
#
# Table name: applied_slas
#
#  id              :bigint           not null, primary key
#  sla_status      :integer          default("active")
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  conversation_id :bigint           not null
#  sla_policy_id   :bigint           not null
#
# Indexes
#
#  index_applied_slas_on_account_id                       (account_id)
#  index_applied_slas_on_account_sla_policy_conversation  (account_id,sla_policy_id,conversation_id) UNIQUE
#  index_applied_slas_on_conversation_id                  (conversation_id)
#  index_applied_slas_on_sla_policy_id                    (sla_policy_id)
#
class AppliedSla < ApplicationRecord
  belongs_to :account
  belongs_to :sla_policy
  belongs_to :conversation

  has_many :sla_events, dependent: :destroy

  validates :account_id, uniqueness: { scope: %i[sla_policy_id conversation_id] }
  before_validation :ensure_account_id

  enum sla_status: { active: 0, hit: 1, missed: 2, active_with_misses: 3 }

  scope :filter_by_date_range, ->(range) { where(created_at: range) if range.present? }
  scope :filter_by_inbox_id, ->(inbox_id) { joins(:conversation).where(conversations: { inbox_id: inbox_id }) if inbox_id.present? }
  scope :filter_by_team_id, ->(team_id) { joins(:conversation).where(conversations: { team_id: team_id }) if team_id.present? }
  scope :filter_by_sla_policy_id, ->(sla_policy_id) { where(sla_policy_id: sla_policy_id) if sla_policy_id.present? }
  scope :filter_by_label_list, lambda { |label_list|
                                 joins(:conversation).where('conversations.cached_label_list LIKE ?', "%#{label_list}%") if label_list.present?
                               }
  scope :filter_by_assigned_agent_id, lambda { |assigned_agent_id|
                                        joins(:conversation).where(conversations: { assignee_id: assigned_agent_id }) if assigned_agent_id.present?
                                      }
  scope :missed, -> { where(sla_status: %i[missed active_with_misses]) }

  after_update_commit :push_conversation_event

  def push_event_data
    {
      id: id,
      sla_id: sla_policy_id,
      sla_status: sla_status,
      created_at: created_at.to_i,
      updated_at: updated_at.to_i,
      sla_description: sla_policy.description,
      sla_name: sla_policy.name,
      sla_first_response_time_threshold: sla_policy.first_response_time_threshold,
      sla_next_response_time_threshold: sla_policy.next_response_time_threshold,
      sla_only_during_business_hours: sla_policy.only_during_business_hours,
      sla_resolution_time_threshold: sla_policy.resolution_time_threshold
    }
  end

  private

  def push_conversation_event
    # right now we simply use `CONVERSATION_UPDATED` event to notify the frontend
    # we can eventually start using `CONVERSATION_SLA_UPDATED` event as required later
    # for now the updated event should suffice

    return unless saved_change_to_sla_status?

    conversation.dispatch_conversation_updated_event
  end

  def ensure_account_id
    self.account_id ||= sla_policy&.account_id
  end
end
