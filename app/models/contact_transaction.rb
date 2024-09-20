# == Schema Information
#
# Table name: contact_transactions
#
#  id                :bigint           not null, primary key
#  custom_attributes :jsonb            not null
#  po_date           :datetime
#  po_note           :string
#  po_value          :float
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :bigint           not null
#  agent_id          :integer
#  contact_id        :bigint           not null
#  product_id        :bigint           not null
#  team_id           :integer
#
# Indexes
#
#  index_contact_transactions_on_account_id  (account_id)
#  index_contact_transactions_on_contact_id  (contact_id)
#  index_contact_transactions_on_product_id  (product_id)
#
class ContactTransaction < ApplicationRecord
  belongs_to :account
  belongs_to :contact
  belongs_to :product
  belongs_to :team, optional: true
  belongs_to :agent, class_name: 'User', optional: true
end
