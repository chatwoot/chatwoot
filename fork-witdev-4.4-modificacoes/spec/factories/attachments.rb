# frozen_string_literal: true

FactoryBot.define do
  factory :attachment do
    account { create(:account) }
    message { create(:message, account: account) }
    file_type { :image }
    meta { {} }

    after(:build) do |attachment|
      attachment.file.attach(
        io: Rails.root.join('spec/assets/avatar.png').open,
        filename: 'avatar.png',
        content_type: 'image/png'
      )
    end

    trait :custom_sticker do
      meta { { 'sticker_type' => 'custom', 'sticker_pack' => 'Default' } }
    end

    trait :with_pack do |pack_name = 'Company'|
      meta { { 'sticker_type' => 'custom', 'sticker_pack' => pack_name } }
    end
  end
end