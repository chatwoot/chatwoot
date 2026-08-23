# == Schema Information
#
# Table name: captain_agent_traces
#
#  id              :bigint           not null, primary key
#  error_reason    :string
#  input_message   :string
#  outcome         :string           default("answered"), not null
#  response        :jsonb            not null
#  source          :string           default("conversation"), not null
#  trace           :jsonb            not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  assistant_id    :bigint           not null
#  conversation_id :bigint
#
# Indexes
#
#  index_captain_agent_traces_on_account_id                      (account_id)
#  index_captain_agent_traces_on_assistant_id                    (assistant_id)
#  index_captain_agent_traces_on_assistant_id_and_created_at     (assistant_id,created_at)
#  index_captain_agent_traces_on_conversation_id                 (conversation_id)
#  index_captain_agent_traces_on_conversation_id_and_created_at  (conversation_id,created_at)
#  index_captain_agent_traces_on_source_and_created_at           (source,created_at)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (assistant_id => captain_assistants.id)
#  fk_rails_...  (conversation_id => conversations.id)
#
class Captain::AgentTrace < ApplicationRecord
  self.table_name = 'captain_agent_traces'

  OUTCOMES = %w[answered handoff offer simple_reply error].freeze
  SOURCES = %w[conversation playground].freeze

  belongs_to :account
  belongs_to :assistant, class_name: 'Captain::Assistant'
  belongs_to :conversation, optional: true, class_name: '::Conversation'

  scope :for_assistant, ->(assistant_id) { where(assistant_id: assistant_id) }
  scope :for_conversation, ->(conversation_id) { where(conversation_id: conversation_id) }
  scope :from_chat, -> { where(source: 'conversation') }
  scope :ordered, -> { order(created_at: :desc, id: :desc) }

  validates :source, inclusion: { in: SOURCES }
  validates :outcome, inclusion: { in: OUTCOMES }
  validates :assistant_id, presence: true
end
