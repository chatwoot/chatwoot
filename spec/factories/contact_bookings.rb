FactoryBot.define do
  factory :contact_booking do
    user { nil }
    contact { nil }
    host_name { 'MyString' }
    booking_location { 'MyString' }
    booking_datetime { '2024-11-12 14:57:50' }
    booking_eventtype { 'MyString' }
  end
end
