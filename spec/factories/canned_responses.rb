# frozen_string_literal: true

# == Schema Information
#
# Table name: canned_responses
#
#  id         :integer          not null, primary key
#  content    :text
#  short_code :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :integer          not null
#
FactoryBot.define do
  factory :canned_response do
    content { 'Content' }
    sequence(:short_code) { |n| "CODE#{n}" }
    account
  end
end
