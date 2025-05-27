FactoryBot.define do
  factory :article, class: 'Article' do
    account
    category
    portal
    locale { 'en' }
    association :author, factory: :user
    title { "#{Faker::Movie.title} #{SecureRandom.hex}" }
    content { 'MyText' }
    description { 'MyDescrption' }
    status { :published }
    slug { title.parameterize }
    views { 0 }
  end
end
