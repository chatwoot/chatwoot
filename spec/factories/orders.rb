# frozen_string_literal: true

FactoryBot.define do
  factory :order do
    sequence(:external_payment_id) { |n| "ORD#{SecureRandom.hex(4).upcase}#{n}" }
    payment_url { "https://payment.example.com/pay/#{external_payment_id}" }
    provider { 'payzah' }
    subtotal { 100.00 }
    total { 100.00 }
    currency { 'KWD' }
    status { :pending }
    payload do
      {
        customer_data: {
          name: 'Test Customer',
          email: 'customer@example.com',
          phone: '+96512345678'
        },
        initiated_at: Time.current.iso8601
      }
    end

    account
    contact { association :contact, account: account }
    conversation { association :conversation, account: account, contact: contact }
    created_by { association :user, account: account }

    trait :initiated do
      status { :initiated }
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

    trait :with_items do
      transient do
        items_count { 1 }
      end

      after(:create) do |order, evaluator|
        create_list(:order_item, evaluator.items_count, order: order)
        order.reload
      end
    end
  end
end
