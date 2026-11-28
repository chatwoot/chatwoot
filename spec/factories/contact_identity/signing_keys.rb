# frozen_string_literal: true

FactoryBot.define do
  factory :contact_identity_signing_key, class: 'ContactIdentity::SigningKey' do
    inbox
  end
end
