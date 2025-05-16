# == Schema Information
#
# Table name: copilot_messages
#
#  id                :bigint           not null, primary key
#  message           :jsonb            not null
#  message_type      :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :bigint           not null
#  copilot_thread_id :bigint           not null
#  user_id           :bigint           not null
#
# Indexes
#
#  index_copilot_messages_on_account_id         (account_id)
#  index_copilot_messages_on_copilot_thread_id  (copilot_thread_id)
#  index_copilot_messages_on_user_id            (user_id)
#
class CopilotMessage < ApplicationRecord
  belongs_to :copilot_thread
  belongs_to :user
  belongs_to :account

  validates :message_type, presence: true, inclusion: { in: %w[user assistant assistant_thinking] }
  validates :message, presence: true
end
