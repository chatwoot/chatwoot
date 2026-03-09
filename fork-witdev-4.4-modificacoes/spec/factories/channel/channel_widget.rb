# frozen_string_literal: true

FactoryBot.define do
  factory :channel_widget, class: 'Channel::WebWidget' do
    sequence(:website_url) { |n| "https://example-#{n}.com" }
    sequence(:widget_color, &:to_s)
    account
    after(:create) do |channel_widget|
      create(:inbox, channel: channel_widget, account: channel_widget.account)
    end
  end
end
