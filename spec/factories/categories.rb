FactoryBot.define do
  factory :category, class: 'Category' do
    portal
    name { 'MyString' }
    description { 'MyText' }
    position { 1 }
    slug { name.parameterize }

    after(:build) do |category|
      category.account ||= category.portal.account
    end
  end
end
