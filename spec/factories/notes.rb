# frozen_string_literal: true

FactoryBot.define do
  factory :note do
    content { 'Hey welcome to chatwoot' }
    account
    user
    updated_by { user }
    contact
    source { 'manual' }
    metadata { {} }
  end
end
