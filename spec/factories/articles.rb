FactoryBot.define do
  factory :article, class: 'Article' do
    account_id { 1 }
    category_id { 1 }
    author_id { 1 }
    title { "#{Faker::Movie.title} #{SecureRandom.hex}" }
    content { 'MyText' }
    description { 'MyDescrption' }
    status { 1 }
    views { 0 }
  end
end
