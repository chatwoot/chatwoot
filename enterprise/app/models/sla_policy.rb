# == Schema Information
#
# Table name: sla_policies
#
#  id                            :bigint           not null, primary key
#  description                   :string
#  first_response_time_threshold :float
#  name                          :string           not null
#  next_response_time_threshold  :float
#  only_during_business_hours    :boolean          default(FALSE)
#  resolution_time_threshold     :float
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  account_id                    :bigint           not null
#
# Indexes
#
#  index_sla_policies_on_account_id  (account_id)
#
class SlaPolicy < ApplicationRecord
  belongs_to :account
  validates :name, presence: true

  has_many :conversations, dependent: :nullify
  has_many :applied_slas, dependent: :destroy

  def push_event_data
    {
      id: id,
      name: name,
      frt: first_response_time_threshold,
      nrt: next_response_time_threshold,
      rt: resolution_time_threshold
    }
  end
end
