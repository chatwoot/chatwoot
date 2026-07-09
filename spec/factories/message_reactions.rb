# frozen_string_literal: true

FactoryBot.define do
  factory :message_reaction do
    message
    account { message.account }
    inbox { message.inbox }
    conversation { message.conversation }
    sender { conversation.contact }
    actor_external_id { SecureRandom.uuid }
    source_id { SecureRandom.uuid }
    external_message_id { message.source_id || "external-#{message.id}" }
    emoji { '👍' }
    reaction_type { 'emoji' }
    direction { :incoming }
    status { :active }
    external_created_at { Time.current }
    metadata { {} }

    trait :removed do
      status { :removed }
    end
  end
end
