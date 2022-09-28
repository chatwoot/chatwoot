# frozen_string_literal: true

FactoryBot.define do
  factory :inbox_member do
    user { create(:user, :with_avatar) }
    inbox
  end
end
