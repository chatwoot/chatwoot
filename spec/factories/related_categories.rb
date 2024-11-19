FactoryBot.define do
  factory :related_category do
    category
    related_category
  end
end
