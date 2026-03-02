# frozen_string_literal: true

# == Schema Information
#
# Table name: mentions
#
#  id              :bigint           not null, primary key
#  mentioned_at    :datetime         not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  conversation_id :bigint           not null
#  user_id         :bigint           not null
#
# Indexes
#
#  index_mentions_on_account_id                   (account_id)
#  index_mentions_on_conversation_id              (conversation_id)
#  index_mentions_on_user_id                      (user_id)
#  index_mentions_on_user_id_and_conversation_id  (user_id,conversation_id) UNIQUE
#
FactoryBot.define do
  factory :mention do
    mentioned_at { Time.current }
    account
    conversation
    user
  end
end
