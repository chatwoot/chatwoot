# == Schema Information
#
# Table name: synapseos_leads
#
#  id              :bigint           not null, primary key
#  disqualified_at :datetime
#  metadata        :jsonb            not null
#  qualified_at    :datetime
#  source          :string
#  status          :integer          default("open"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  assignee_id     :bigint
#  contact_id      :bigint
#  conversation_id :bigint           not null
#
# Indexes
#
#  index_synapseos_leads_on_account_id                      (account_id)
#  index_synapseos_leads_on_account_id_and_conversation_id  (account_id,conversation_id) UNIQUE
#  index_synapseos_leads_on_account_id_and_created_at       (account_id,created_at)
#  index_synapseos_leads_on_account_id_and_status           (account_id,status)
#  index_synapseos_leads_on_assignee_id                     (assignee_id)
#  index_synapseos_leads_on_contact_id                      (contact_id)
#  index_synapseos_leads_on_conversation_id                 (conversation_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (assignee_id => users.id)
#  fk_rails_...  (contact_id => contacts.id)
#  fk_rails_...  (conversation_id => conversations.id)
#
module Synapseos
  class Lead < ApplicationRecord
    self.table_name = 'synapseos_leads'

    belongs_to :account
    belongs_to :conversation
    belongs_to :contact, optional: true
    belongs_to :assignee, class_name: 'User', optional: true

    has_many :deals, class_name: 'Synapseos::Deal', dependent: :destroy

    enum status: { open: 0, qualified: 1, disqualified: 2, converted: 3 }

    validates :status, presence: true
    validates :conversation_id, uniqueness: { scope: :account_id }
  end
end
