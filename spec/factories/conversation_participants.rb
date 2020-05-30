FactoryBot.define do
  factory :conversation_participant do
    contact { nil }
    conversation { nil }
    uuid { SecureRandom.uuid }
  end
end
