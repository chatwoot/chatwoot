# == Schema Information
#
# Table name: sla_policies
#
#  id                         :bigint           not null, primary key
#  first_response_time        :float
#  name                       :string           not null
#  description                :string
#  only_during_business_hours :boolean          default(FALSE)
#  next_response_time         :float
#  resolution_time            :float
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  account_id                 :bigint           not null
#
# Indexes
#
#  index_sla_policies_on_account_id  (account_id)
#
class SlaPolicy < ApplicationRecord
  belongs_to :account
  validates :name, presence: true

  has_many :conversations, dependent: :nullify
end
