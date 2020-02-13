FactoryBot.define do
  factory :webhook do
    account_id { 1 }
    inbox_id { 1 }
    urls { ['MyString'] }
  end
end
