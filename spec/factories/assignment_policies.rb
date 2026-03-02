# == Schema Information
#
# Table name: assignment_policies
#
#  id                       :bigint           not null, primary key
#  assignment_order         :integer          default("round_robin"), not null
#  conversation_priority    :integer          default("earliest_created"), not null
#  description              :text
#  enabled                  :boolean          default(TRUE), not null
#  fair_distribution_limit  :integer          default(100), not null
#  fair_distribution_window :integer          default(3600), not null
#  name                     :string(255)      not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  account_id               :bigint           not null
#
# Indexes
#
#  index_assignment_policies_on_account_id           (account_id)
#  index_assignment_policies_on_account_id_and_name  (account_id,name) UNIQUE
#  index_assignment_policies_on_enabled              (enabled)
#
FactoryBot.define do
  factory :assignment_policy do
    account
    sequence(:name) { |n| "Assignment Policy #{n}" }
    description { 'Test assignment policy description' }
    assignment_order { 0 }
    conversation_priority { 0 }
    fair_distribution_limit { 10 }
    fair_distribution_window { 3600 }
    enabled { true }
  end
end
