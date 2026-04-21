# == Schema Information
#
# Table name: synapseos_deals
#
#  id          :bigint           not null, primary key
#  amount      :decimal(14, 2)   default(0.0)
#  closed_at   :datetime
#  currency    :string           default("BRL")
#  metadata    :jsonb            not null
#  status      :integer          default("pending"), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :bigint           not null
#  assignee_id :bigint
#  lead_id     :bigint           not null
#
# Indexes
#
#  index_synapseos_deals_on_account_id                (account_id)
#  index_synapseos_deals_on_account_id_and_closed_at  (account_id,closed_at)
#  index_synapseos_deals_on_account_id_and_status     (account_id,status)
#  index_synapseos_deals_on_assignee_id               (assignee_id)
#  index_synapseos_deals_on_lead_id                   (lead_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (assignee_id => users.id)
#  fk_rails_...  (lead_id => synapseos_leads.id)
#
module Synapseos
  class Deal < ApplicationRecord
    self.table_name = 'synapseos_deals'

    belongs_to :account
    belongs_to :lead, class_name: 'Synapseos::Lead'
    belongs_to :assignee, class_name: 'User', optional: true

    enum status: { pending: 0, won: 1, lost: 2 }

    validates :status, presence: true
    validates :amount, numericality: { greater_than_or_equal_to: 0 }
  end
end
