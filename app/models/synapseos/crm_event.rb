# == Schema Information
#
# Table name: synapseos_crm_events
#
#  id              :bigint           not null, primary key
#  event_type      :string           not null
#  metadata        :jsonb            not null
#  created_at      :datetime         not null
#  account_id      :bigint           not null
#  conversation_id :bigint
#  user_id         :bigint
#
# Indexes
#
#  idx_synapseos_crm_events_conv_time             (account_id,conversation_id,created_at)
#  idx_synapseos_crm_events_type_time             (account_id,event_type,created_at)
#  index_synapseos_crm_events_on_account_id       (account_id)
#  index_synapseos_crm_events_on_conversation_id  (conversation_id)
#  index_synapseos_crm_events_on_user_id          (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (conversation_id => conversations.id)
#  fk_rails_...  (user_id => users.id)
#
module Synapseos
  class CrmEvent < ApplicationRecord
    self.table_name = 'synapseos_crm_events'

    # Append-only audit log; updates are not allowed.
    EVENT_TYPES = %w[
      lead_created
      lead_qualified
      lead_disqualified
      deal_created
      deal_won
      deal_lost
      bot_takeover
      human_rescue
      appointment_confirmed
      private_note_added
    ].freeze

    belongs_to :account
    belongs_to :conversation, optional: true
    belongs_to :user, optional: true

    validates :event_type, presence: true, inclusion: { in: EVENT_TYPES }
  end
end
