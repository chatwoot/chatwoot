# frozen_string_literal: true

FactoryBot.define do
  factory :custom_filter do
    sequence(:name) { |n| "Custom Filter #{n}" }
    filter_type { 0 }
    query { { payload: [{ values: [:open], attribute_key: 'status', filter_operator: 'equal_to', attribute_model: 'standard' }] } }
    user
    account
  end
end
