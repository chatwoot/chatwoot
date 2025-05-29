FactoryBot.define do
  factory :aiagent_document, class: 'Aiagent::Document' do
    name { Faker::File.file_name }
    external_link { Faker::Internet.unique.url }
    content { Faker::Lorem.paragraphs.join("\n\n") }
    association :topic, factory: :aiagent_topic
    association :account
  end
end
