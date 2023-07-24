FactoryBot.define do
  factory :category, class: 'Category' do
    portal { portal }
    name { 'MyString' }
    description { 'MyText' }
    position { 1 }

    after(:build) do |category|
      category.account ||= category.portal.account
    end
  end
end
