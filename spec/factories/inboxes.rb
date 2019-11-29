# frozen_string_literal: true

# == Schema Information
#
# Table name: inboxes
#
#  id           :integer          not null, primary key
#  channel_type :string
#  name         :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :integer          not null
#  channel_id   :integer          not null
#
# Indexes
#
#  index_inboxes_on_account_id  (account_id)
#


FactoryBot.define do
  factory :inbox do
    account
    association :channel, factory: :channel_widget
    name { 'Inbox' }
  end
end
