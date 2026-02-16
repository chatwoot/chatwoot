# frozen_string_literal: true

FactoryBot.define do
  factory :attachment do
    message
    account { message.account }
    file_type { :image }

    trait :audio do
      file_type { :audio }
    end

    trait :image do
      file_type { :image }
    end

    trait :video do
      file_type { :video }
    end

    trait :file do
      file_type { :file }
    end
  end
end
