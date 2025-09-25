FactoryBot.define do
  factory :captain_document, class: 'Captain::Document' do
    name { Faker::File.file_name }
    external_link { Faker::Internet.unique.url }
    content { Faker::Lorem.paragraphs.join("\n\n") }
    association :assistant, factory: :captain_assistant
    association :account
  end
end
