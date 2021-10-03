FactoryBot.define do
  factory :push_key do
    provider { 'vapid' }
    public_key { 'MyString' }
    private_key { 'MyString' }
  end
end
