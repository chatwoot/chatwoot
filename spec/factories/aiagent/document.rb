FactoryBot.define do
  factory :aiagent_document, class: 'Aiagent::Document' do
    name { Faker::File.file_name }
    external_link { Faker::Internet.unique.url }
    content { Faker::Lorem.paragraphs.join("\n\n") }
    association :assistant, factory: :aiagent_assistant
    association :account
  end
end
