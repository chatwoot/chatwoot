# frozen_string_literal: true

FactoryBot.define do
  factory :product do
    sequence(:title_en) { |n| "Product #{n}" }
    price { 10.00 }
    stock { 100 }
    account

    trait :with_image do
      image { fixture_file_upload(Rails.root.join('spec/assets/avatar.png'), 'image/png') }
    end

    trait :out_of_stock do
      stock { 0 }
    end

    trait :unlimited_stock do
      stock { nil }
    end
  end
end
