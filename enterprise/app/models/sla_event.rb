# == Schema Information
#
# Table name: sla_events
#
#  id              :bigint           not null, primary key
#  event_type      :string
#  meta            :jsonb
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  applied_sla_id  :bigint           not null
#  conversation_id :bigint           not null
#
# Indexes
#
#  index_sla_events_on_applied_sla_id   (applied_sla_id)
#  index_sla_events_on_conversation_id  (conversation_id)
#
class SlaEvent < ApplicationRecord
  belongs_to :applied_sla
  belongs_to :conversation

  enum event_type: { frt: 0, nrt: 1, rt: 2 }

  before_validation :ensure_applied_sla_id
end
