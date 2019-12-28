# frozen_string_literal: true

FactoryBot.define do
  factory :facebook_page, class: 'Channel::FacebookPage' do
    sequence(:page_id) { |n| n }
    sequence(:user_access_token) { |n| "random-token-#{n}" }
    sequence(:name) { |n| "Facebook Page #{n}" }
    sequence(:page_access_token) { |n| "page-access-token-#{n}" }
    account
  end
end
