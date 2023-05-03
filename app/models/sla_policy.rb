# == Schema Information
#
# Table name: sla_policies
#
#  id                         :bigint           not null, primary key
#  frt_threshold              :float
#  name                       :string           not null
#  only_during_business_hours :boolean          default(FALSE)
#  rt_threshold               :float
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
end
