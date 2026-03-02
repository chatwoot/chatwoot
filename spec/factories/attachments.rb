# frozen_string_literal: true

# == Schema Information
#
# Table name: attachments
#
#  id               :integer          not null, primary key
#  coordinates_lat  :float            default(0.0)
#  coordinates_long :float            default(0.0)
#  extension        :string
#  external_url     :string
#  fallback_title   :string
#  file_type        :integer          default("image")
#  meta             :jsonb
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :integer          not null
#  message_id       :integer          not null
#
# Indexes
#
#  index_attachments_on_account_id  (account_id)
#  index_attachments_on_message_id  (message_id)
#
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
