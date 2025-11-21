# frozen_string_literal: true

FactoryBot.define do
  factory :payment_link do
    sequence(:external_payment_id) { |n| "PAY#{SecureRandom.hex(4).upcase}#{n}" }
    payment_url { "https://payment.example.com/pay/#{external_payment_id}" }
    provider { 'payzah' }
    amount { 100.00 }
    currency { 'KWD' }
    status { :pending }
    payload do
      {
        customer_data: {
          name: 'Test Customer',
          email: 'customer@example.com',
          phone: '+96512345678'
        }
      }
    end

    account
    contact { association :contact, account: account }
    conversation { association :conversation, account: account, contact: contact }
    message { association :message, conversation: conversation, account: account }
    created_by { association :user, account: account }

    trait :initiated do
      status { :initiated }
      external_payment_id { nil }
      payment_url { '' }
    end

    trait :paid do
      status { :paid }
      payload do
        {
          customer_data: { name: 'Test Customer' },
          paid_at: Time.current.iso8601
        }
      end
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
