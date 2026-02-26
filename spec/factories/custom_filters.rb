# frozen_string_literal: true

# == Schema Information
#
# Table name: custom_filters
#
#  id          :bigint           not null, primary key
#  filter_type :integer          default("conversation"), not null
#  name        :string           not null
#  query       :jsonb            not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :bigint           not null
#  user_id     :bigint           not null
#
# Indexes
#
#  index_custom_filters_on_account_id  (account_id)
#  index_custom_filters_on_user_id     (user_id)
#
FactoryBot.define do
  factory :custom_filter do
    sequence(:name) { |n| "Custom Filter #{n}" }
    filter_type { 0 }
    query { { labels: ['customer-support'], status: 'open' } }
    user
    account
  end
end
