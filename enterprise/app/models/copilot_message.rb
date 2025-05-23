# == Schema Information
#
# Table name: copilot_messages
#
#  id                :bigint           not null, primary key
#  message           :jsonb            not null
#  message_type      :integer          default("user")
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :bigint           not null
#  copilot_thread_id :bigint           not null
#
# Indexes
#
#  index_copilot_messages_on_account_id         (account_id)
#  index_copilot_messages_on_copilot_thread_id  (copilot_thread_id)
#
class CopilotMessage < ApplicationRecord
  belongs_to :copilot_thread
  belongs_to :account

  before_validation :ensure_account

  enum message_type: { user: 0, assistant: 1, assistant_thinking: 2 }

  validates :message_type, presence: true, inclusion: { in: message_types.keys }
  validates :message, presence: true
  validate :validate_message_attributes

  after_create_commit :broadcast_message

  def push_event_data
    {
      id: id,
      message: message,
      message_type: message_type,
      created_at: created_at.to_i,
      copilot_thread: copilot_thread.push_event_data
    }
  end

  private

  def ensure_account
    self.account = copilot_thread.account
  end

  def broadcast_message
    Rails.configuration.dispatcher.dispatch(COPILOT_MESSAGE_CREATED, Time.zone.now, copilot_message: self)
  end

  def validate_message_attributes
    return if message.blank?

    allowed_keys = %w[content reasoning function_name]
    invalid_keys = message.keys - allowed_keys

    errors.add(:message, "contains invalid attributes: #{invalid_keys.join(', ')}") if invalid_keys.any?
  end
end
