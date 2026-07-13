# == Schema Information
#
# Table name: captain_sessions
#
#  id               :bigint           not null, primary key
#  credits_consumed :float
#  document_ids     :jsonb
#  faq_ids          :jsonb
#  llm_model        :string
#  result_type      :string
#  run_context      :jsonb
#  scenario_ids     :jsonb
#  session_type     :integer          not null
#  subject_type     :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :bigint           not null
#  assistant_id     :bigint           not null
#  result_id        :bigint
#  subject_id       :bigint           not null
#  user_id          :bigint
#
# Indexes
#
#  idx_on_account_id_session_type_created_at_a396daca19  (account_id,session_type,created_at)
#  index_captain_sessions_on_account_id                  (account_id)
#  index_captain_sessions_on_assistant_id                (assistant_id)
#  index_captain_sessions_on_result                      (result_type,result_id)
#  index_captain_sessions_on_subject                     (subject_type,subject_id)
#  index_captain_sessions_on_user_id                     (user_id)
#
class Captain::Session < ApplicationRecord
  self.table_name = 'captain_sessions'

  SUBJECT_TYPES = { 'assistant' => 'Conversation', 'copilot' => 'CopilotThread' }.freeze
  RESULT_TYPES = { 'assistant' => 'Message', 'copilot' => 'CopilotMessage' }.freeze

  belongs_to :account
  belongs_to :assistant, class_name: 'Captain::Assistant'
  belongs_to :user, optional: true
  belongs_to :subject, ->(session) { where(account_id: session.account_id) }, polymorphic: true
  belongs_to :result, ->(session) { where(account_id: session.account_id) }, polymorphic: true, optional: true

  enum :session_type, { assistant: 0, copilot: 1 }, prefix: :session

  validate :subject_type_matches_session_type
  validate :result_type_matches_session_type, if: -> { result_type.present? }

  private

  def subject_type_matches_session_type
    expected_type = SUBJECT_TYPES[session_type]
    return if subject_type == expected_type

    errors.add(:subject_type, "must be #{expected_type} for #{session_type} sessions")
  end

  def result_type_matches_session_type
    expected_type = RESULT_TYPES[session_type]
    return if result_type == expected_type

    errors.add(:result_type, "must be #{expected_type} for #{session_type} sessions")
  end
end
