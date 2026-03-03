# frozen_string_literal: true

# == Schema Information
#
# Table name: products
#
#  id             :bigint           not null, primary key
#  description_ar :text
#  description_en :text
#  price          :decimal(10, 2)   not null
#  stock          :integer
#  title_ar       :string
#  title_en       :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  account_id     :bigint           not null
#
# Indexes
#
#  index_products_on_account_id               (account_id)
#  index_products_on_account_id_and_title_en  (account_id,title_en) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
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
