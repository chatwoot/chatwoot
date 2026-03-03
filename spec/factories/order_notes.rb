# frozen_string_literal: true

# == Schema Information
#
# Table name: order_notes
#
#  id         :bigint           not null, primary key
#  content    :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#  order_id   :bigint           not null
#  user_id    :bigint
#
# Indexes
#
#  index_order_notes_on_account_id  (account_id)
#  index_order_notes_on_order_id    (order_id)
#  index_order_notes_on_user_id     (user_id)
#
FactoryBot.define do
  factory :order_note do
    content { 'This is a test note' }

    order
    user { association :user, account: order.account }
    account { order.account }
  end
end
