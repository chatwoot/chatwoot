# frozen_string_literal: true

# == Schema Information
#
# Table name: channel_facebook_pages
#
#  id                :integer          not null, primary key
#  page_access_token :string           not null
#  user_access_token :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :integer          not null
#  instagram_id      :string
#  page_id           :string           not null
#
# Indexes
#
#  index_channel_facebook_pages_on_page_id                 (page_id)
#  index_channel_facebook_pages_on_page_id_and_account_id  (page_id,account_id) UNIQUE
#
FactoryBot.define do
  factory :channel_facebook_page, class: 'Channel::FacebookPage' do
    page_access_token { SecureRandom.uuid }
    user_access_token { SecureRandom.uuid }
    page_id { SecureRandom.uuid }
    inbox
    account
  end
end
