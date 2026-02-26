# frozen_string_literal: true

FactoryBot.define do
  factory :inbox_signature do
    user
    inbox
    message_signature { '<p>Best regards,<br>Test Agent</p>' }
    signature_position { 'top' }
    signature_separator { 'blank' }
  end
end
