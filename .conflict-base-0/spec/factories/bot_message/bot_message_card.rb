# frozen_string_literal: true

FactoryBot.define do
  factory :bot_message_card, class: Hash do
    title { Faker::Book.name }
    description { Faker::Movie.quote }
    media_url { 'https://chatwoot-assets.local/sample.png' }
    actions do
      [{
        text: 'Select',
        type: 'postback',
        payload: 'TACOS'
      }, {
        text: 'More info',
        type: 'link',
        uri: 'http://example.org'
      }]
    end

    initialize_with { attributes }
  end
end
