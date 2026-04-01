# == Schema Information
#
# Table name: inbox_assignment_policies
#
#  id                   :bigint           not null, primary key
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  assignment_policy_id :bigint           not null
#  inbox_id             :bigint           not null
#
# Indexes
#
#  index_inbox_assignment_policies_on_assignment_policy_id  (assignment_policy_id)
#  index_inbox_assignment_policies_on_inbox_id              (inbox_id) UNIQUE
#
FactoryBot.define do
  factory :inbox_assignment_policy do
    inbox
    assignment_policy
  end
end
