# frozen_string_literal: true

FactoryBot.define do
  factory :payment_link do
    sequence(:payment_id) { |n| "PAY#{SecureRandom.hex(4).upcase}#{n}" }
    sequence(:track_id) { |n| "TRACK#{SecureRandom.hex(4).upcase}#{n}" }
    payment_url { "https://payment.example.com/pay/#{payment_id}" }
    amount { 100.00 }
    currency { 'KWD' }
    status { :pending }
    customer_data do
      {
        name: 'Test Customer',
        email: 'customer@example.com',
        phone: '+96512345678'
      }
    end

    account
    contact { association :contact, account: account }
    conversation { association :conversation, account: account, contact: contact }
    message { association :message, conversation: conversation, account: account }
    created_by { association :user, account: account }

    trait :paid do
      status { :paid }
      paid_at { Time.current }
    end

    trait :failed do
      status { :failed }
    end

    trait :expired do
      status { :expired }
    end

    trait :cancelled do
      status { :cancelled }
    end
  end
end
