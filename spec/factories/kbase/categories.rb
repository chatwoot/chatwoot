FactoryBot.define do
  factory :kbase_category, class: 'Kbase::Category' do
    portal { kbase_portal }
    name { 'MyString' }
    description { 'MyText' }
    position { 1 }

    after(:build) do |category|
      category.account ||= category.portal.account
    end
  end
end
