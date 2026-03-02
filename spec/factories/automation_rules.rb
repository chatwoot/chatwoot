# == Schema Information
#
# Table name: automation_rules
#
#  id          :bigint           not null, primary key
#  actions     :jsonb            not null
#  active      :boolean          default(TRUE), not null
#  conditions  :jsonb            not null
#  description :text
#  event_name  :string           not null
#  name        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :bigint           not null
#
# Indexes
#
#  index_automation_rules_on_account_id  (account_id)
#
FactoryBot.define do
  factory :automation_rule do
    account
    name { 'Test Automation Rule' }
    event_name { 'conversation_status_changed' }
    conditions { [{ 'values': ['resolved'], 'attribute_key': 'status', 'query_operator': nil, 'filter_operator': 'equal_to' }] }
    actions do
      [
        {
          'action_name' => 'send_email_to_team', 'action_params' => {
            'message' => 'Please pay attention to this conversation, its from high priority customer', 'team_ids' => [1]
          }
        },
        { 'action_name' => 'assign_team', 'action_params' => [1] },
        { 'action_name' => 'add_label', 'action_params' => %w[support priority_customer] },
        { 'action_name' => 'assign_agent', 'action_params' => [1, 2, 3, 4] }
      ]
    end
  end
end
