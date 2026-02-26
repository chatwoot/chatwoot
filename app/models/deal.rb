# == Schema Information
#
# Table name: deals
#
#  id                :bigint           not null, primary key
#  name              :string           not null
#  status            :integer          default(0)
#  value             :decimal(10, 2)   default(0.0)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :bigint           not null
#  contact_id        :bigint           not null
#  pipeline_stage_id :bigint           not null
#  conversation_id   :bigint
#
# Indexes
#
#  index_deals_on_account_id         (account_id)
#  index_deals_on_contact_id         (contact_id)
#  index_deals_on_conversation_id    (conversation_id)
#  index_deals_on_pipeline_stage_id  (pipeline_stage_id)
#

class Deal < ApplicationRecord
  belongs_to :account
  belongs_to :contact
  belongs_to :pipeline_stage
  belongs_to :conversation, optional: true

  enum status: { open: 0, won: 1, lost: 2 }

  validates :name, presence: true
  validates :status, presence: true
end
