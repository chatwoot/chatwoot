# frozen_string_literal: true

# == Schema Information
#
# Table name: payment_links
#
#  id                  :bigint           not null, primary key
#  amount              :decimal(10, 2)   not null
#  currency            :string           not null
#  payload             :jsonb            not null
#  payment_url         :string
#  provider            :string           not null
#  status              :integer          default("initiated"), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  account_id          :bigint           not null
#  contact_id          :bigint           not null
#  conversation_id     :bigint           not null
#  created_by_id       :bigint           not null
#  external_payment_id :string
#  message_id          :bigint
#
# Indexes
#
#  index_payment_links_on_account_id           (account_id)
#  index_payment_links_on_contact_id           (contact_id)
#  index_payment_links_on_conversation_id      (conversation_id)
#  index_payment_links_on_created_by_id        (created_by_id)
#  index_payment_links_on_external_payment_id  (external_payment_id) UNIQUE
#  index_payment_links_on_message_id           (message_id)
#  index_payment_links_on_provider             (provider)
#  index_payment_links_on_status               (status)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (contact_id => contacts.id)
#  fk_rails_...  (conversation_id => conversations.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (message_id => messages.id)
#
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
