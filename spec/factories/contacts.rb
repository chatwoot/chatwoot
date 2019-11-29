# frozen_string_literal: true

# == Schema Information
#
# Table name: contacts
#
#  id           :integer          not null, primary key
#  avatar       :string
#  email        :string
#  name         :string
#  phone_number :string
#  pubsub_token :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :integer          not null
#
# Indexes
#
#  index_contacts_on_account_id    (account_id)
#  index_contacts_on_pubsub_token  (pubsub_token) UNIQUE
#


FactoryBot.define do
  factory :contact do
    sequence(:name) { |n| "Widget #{n}" }
    sequence(:email) { |n| "widget-#{n}@example.com" }
    phone_number { '+123456789011' }
    account
  end
end
