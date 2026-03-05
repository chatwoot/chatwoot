# frozen_string_literal: true

# == Schema Information
#
# Table name: orders
#
#  id                  :bigint           not null, primary key
#  created_by_type     :string           default("User")
#  currency            :string           not null
#  delivery_address    :jsonb
#  payload             :jsonb            not null
#  payment_url         :string
#  provider            :string           not null
#  status              :integer          default("initiated"), not null
#  subtotal            :decimal(10, 2)   not null
#  total               :decimal(10, 2)   not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  account_id          :bigint           not null
#  contact_id          :bigint           not null
#  conversation_id     :bigint           not null
#  created_by_id       :bigint
#  external_payment_id :string
#  message_id          :bigint
#
# Indexes
#
#  index_carts_on_created_by            (created_by_type,created_by_id)
#  index_orders_on_account_id           (account_id)
#  index_orders_on_contact_id           (contact_id)
#  index_orders_on_conversation_id      (conversation_id)
#  index_orders_on_created_by_id        (created_by_id)
#  index_orders_on_external_payment_id  (external_payment_id) UNIQUE
#  index_orders_on_message_id           (message_id)
#  index_orders_on_status               (status)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (contact_id => contacts.id)
#  fk_rails_...  (conversation_id => conversations.id)
#  fk_rails_...  (message_id => messages.id)
#
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
