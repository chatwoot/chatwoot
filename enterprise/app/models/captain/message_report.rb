# == Schema Information
#
# Table name: captain_message_reports
#
#  id              :bigint           not null, primary key
#  description     :text
#  report_reason   :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  conversation_id :bigint           not null
#  message_id      :bigint           not null
#  user_id         :bigint           not null
#
# Indexes
#
#  index_captain_message_reports_on_account_id       (account_id)
#  index_captain_message_reports_on_conversation_id  (conversation_id)
#  index_captain_message_reports_on_message_id       (message_id)
#  index_captain_message_reports_on_user_id          (user_id)
#
class Captain::MessageReport < ApplicationRecord
  self.table_name = 'captain_message_reports'

  REPORT_REASONS = %w[incorrect_information inappropriate_response incomplete_response outdated_information other].freeze

  belongs_to :account
  # `Captain::Conversation` exists as a job namespace, so the association would
  # resolve to that module instead of the top-level model without this override.
  belongs_to :conversation, class_name: '::Conversation'
  belongs_to :message
  belongs_to :user

  validates :report_reason, presence: true, inclusion: { in: REPORT_REASONS }

  before_validation :ensure_account_and_conversation

  private

  def ensure_account_and_conversation
    return if message.blank?

    self.account ||= message.account
    self.conversation ||= message.conversation
  end
end
