FactoryBot.define do
  factory :blob, class: 'ActiveStorage::Blob' do
    sequence(:key) { |n| "blob_key_#{n}" }
    filename { 'example.jpg' }
    content_type { 'image/jpeg' }
    metadata { '' }
    checksum { 'checksum' }
    byte_size { 1234 }

    trait :image do
      content_type { 'image/jpeg' }
    end

    trait :text do
      content_type { 'text/plain' }
      filename { 'example.txt' }
    end
  end
end
