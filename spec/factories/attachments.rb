FactoryBot.define do
  factory :attachment do
    account
    message
    file_type { :image }

    after(:build) do |attachment|
      attachment.file.attach(
        io: File.open(Rails.root.join('spec/assets/sample.png')),
        filename: 'sample.png',
        content_type: 'image/png'
      )
    end

    trait :with_pdf do
      file_type { :file }
      after(:build) do |attachment|
        attachment.file.attach(
          io: File.open(Rails.root.join('spec/assets/attachment.pdf')),
          filename: 'attachment.pdf',
          content_type: 'application/pdf'
        )
      end
    end

    trait :with_audio do
      file_type { :audio }
      after(:build) do |attachment|
        attachment.file.attach(
          io: StringIO.new('fake audio content'),
          filename: 'audio.mp3',
          content_type: 'audio/mp3'
        )
      end
    end

    trait :location do
      file_type { :location }
      coordinates_lat { 37.7749 }
      coordinates_long { -122.4194 }
      fallback_title { 'San Francisco, CA' }
      external_url { 'https://maps.google.com/?q=37.7749,-122.4194' }
    end
  end
end