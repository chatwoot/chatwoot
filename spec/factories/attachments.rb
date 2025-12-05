FactoryBot.define do
  factory :attachment do
    association :account
    association :message
    file_type { :audio }

    after(:build) do |attachment|
      attachment.file.attach(
        io: File.open(Rails.root.join('spec/assets/sample.pdf')),
        filename: 'test-audio.ogg',
        content_type: 'audio/ogg'
      )
    end
  end
end
