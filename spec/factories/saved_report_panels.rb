# frozen_string_literal: true

FactoryBot.define do
  factory :saved_report_panel do
    account
    association :created_by, factory: :user
    sequence(:name) { |n| "Report panel #{n}" }
    date_preset { 'last_7_days' }
    business_hours { false }
    favorite { false }
    filters { [] }
    widgets do
      [
        {
          'id' => 'w_metric_1',
          'type' => 'metric',
          'title' => 'Conversations',
          'metric' => 'conversations_count',
          'scope_type' => 'account'
        }
      ]
    end
  end
end
