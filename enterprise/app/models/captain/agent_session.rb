# == Schema Information
#
# Table name: agent_sessions
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
#  idx_on_account_id_result_type_result_id_ca66c00cd7    (account_id,result_type,result_id)
#  idx_on_account_id_session_type_created_at_c20a14bd4e  (account_id,session_type,created_at)
#  idx_on_account_id_subject_type_subject_id_6d60963b3d  (account_id,subject_type,subject_id)
#  index_agent_sessions_on_account_id                    (account_id)
#  index_agent_sessions_on_assistant_id                  (assistant_id)
#  index_agent_sessions_on_user_id                       (user_id)
#
class Captain::AgentSession < ApplicationRecord
  self.table_name = 'agent_sessions'

  SUBJECT_TYPES = { 'assistant' => 'Conversation', 'copilot' => 'CopilotThread' }.freeze
  RESULT_TYPES = { 'assistant' => 'Message', 'copilot' => 'CopilotMessage' }.freeze

  belongs_to :account
  belongs_to :assistant, class_name: 'Captain::Assistant'
  belongs_to :user, optional: true
  belongs_to :subject, ->(session) { where(account_id: session.account_id) }, polymorphic: true
  belongs_to :result, ->(session) { where(account_id: session.account_id) }, polymorphic: true, optional: true

  enum :session_type, { assistant: 0, copilot: 1 }, prefix: :session

  before_validation :ensure_account

  validate :subject_type_matches_session_type
  validate :result_type_matches_session_type, if: -> { result_type.present? }
  validate :subject_belongs_to_account
  validate :result_belongs_to_account, if: -> { result_id.present? }

  private

  def ensure_account
    self.account = assistant&.account
  end

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

  def subject_belongs_to_account
    return if subject.nil? || subject.account_id == account_id

    errors.add(:subject, 'must belong to the session account')
  end

  def result_belongs_to_account
    target_class = result_type.safe_constantize
    actual_account_id = target_class && target_class.unscoped.where(id: result_id).pick(:account_id)
    return if actual_account_id == account_id

    errors.add(:result, 'must belong to the session account')
  end
end
