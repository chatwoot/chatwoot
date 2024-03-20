# == Schema Information
#
# Table name: sla_events
#
#  id              :bigint           not null, primary key
#  event_type      :integer
#  meta            :jsonb
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  applied_sla_id  :bigint           not null
#  conversation_id :bigint           not null
#  inbox_id        :bigint           not null
#  sla_policy_id   :bigint           not null
#
# Indexes
#
#  index_sla_events_on_account_id       (account_id)
#  index_sla_events_on_applied_sla_id   (applied_sla_id)
#  index_sla_events_on_conversation_id  (conversation_id)
#  index_sla_events_on_inbox_id         (inbox_id)
#  index_sla_events_on_sla_policy_id    (sla_policy_id)
#
class SlaEvent < ApplicationRecord
  belongs_to :account
  belongs_to :inbox
  belongs_to :conversation
  belongs_to :sla_policy
  belongs_to :applied_sla

  enum event_type: { frt: 0, nrt: 1, rt: 2 }

  before_validation :ensure_applied_sla_id, :ensure_account_id, :ensure_inbox_id, :ensure_sla_policy_id

  private

  def ensure_applied_sla_id
    self.applied_sla_id ||= AppliedSla.find_by(conversation_id: conversation_id)&.last&.id
  end

  def ensure_account_id
    self.account_id ||= conversation&.account_id
  end

  def ensure_inbox_id
    self.inbox_id ||= conversation&.inbox_id
  end

  def ensure_sla_policy_id
    self.sla_policy_id ||= applied_sla&.sla_policy_id
  end
end
