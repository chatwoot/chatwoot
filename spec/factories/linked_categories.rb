FactoryBot.define do
  factory :linked_category do
    category
    linked_category
  end
end
