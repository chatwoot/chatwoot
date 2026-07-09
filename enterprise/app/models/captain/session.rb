# == Schema Information
#
# Table name: captain_sessions
#
#  id               :bigint           not null, primary key
#  credits_consumed :float
#  document_ids     :jsonb
#  faq_ids          :jsonb
#  llm_model        :string
#  run_context      :jsonb
#  session_type     :integer          not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :bigint           not null
#  assistant_id     :bigint           not null
#  result_id        :bigint
#  scenario_id      :bigint
#  subject_id       :bigint           not null
#  user_id          :bigint
#
# Indexes
#
#  idx_on_account_id_session_type_created_at_a396daca19   (account_id,session_type,created_at)
#  index_captain_sessions_on_account_id                   (account_id)
#  index_captain_sessions_on_assistant_id                 (assistant_id)
#  index_captain_sessions_on_session_type_and_result_id   (session_type,result_id)
#  index_captain_sessions_on_session_type_and_subject_id  (session_type,subject_id)
#  index_captain_sessions_on_user_id                      (user_id)
#
class Captain::Session < ApplicationRecord
  self.table_name = 'captain_sessions'

  belongs_to :account
  belongs_to :assistant, class_name: 'Captain::Assistant'
  belongs_to :user, optional: true
  belongs_to :scenario, class_name: 'Captain::Scenario', optional: true

  enum :session_type, { assistant: 0, copilot: 1 }, prefix: :session

  validates :subject_id, presence: true

  def subject
    session_assistant? ? Conversation.find_by(id: subject_id) : CopilotThread.find_by(id: subject_id)
  end

  def result
    return if result_id.blank?

    session_assistant? ? Message.find_by(id: result_id) : CopilotMessage.find_by(id: result_id)
  end
end
