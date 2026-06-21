# == Schema Information
#
# Table name: captain_message_generations
#
#  id              :bigint           not null, primary key
#  citations       :jsonb            not null
#  generation_path :jsonb            not null
#  model           :string
#  reasoning       :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  assistant_id    :bigint           not null
#  conversation_id :bigint           not null
#  message_id      :bigint           not null
#
# Indexes
#
#  index_captain_message_generations_on_account_id       (account_id)
#  index_captain_message_generations_on_assistant_id     (assistant_id)
#  index_captain_message_generations_on_conversation_id  (conversation_id)
#  index_captain_message_generations_on_message_id       (message_id) UNIQUE
#
class Captain::MessageGeneration < ApplicationRecord
  self.table_name = 'captain_message_generations'

  belongs_to :account
  # `Captain::Conversation` exists as a job namespace, so the association would
  # resolve to that module instead of the top-level model without this override.
  belongs_to :conversation, class_name: '::Conversation'
  belongs_to :message
  belongs_to :assistant, class_name: 'Captain::Assistant'

  before_validation :ensure_account_and_conversation

  def self.record!(message:, assistant:, reasoning:, used_sources:, metadata: nil)
    metadata ||= {}
    create!(
      message: message,
      assistant: assistant,
      reasoning: reasoning,
      model: metadata[:model],
      citations: flag_used_citations(metadata[:citations], used_sources),
      generation_path: metadata[:generation_path] || []
    )
  end

  # A found FAQ counts as "used" when the assistant lists its Source ID (the
  # AssistantResponse id) in the `used_sources` field of its response.
  def self.flag_used_citations(citations, used_sources)
    used = Array(used_sources).map(&:to_s)

    Array(citations).map do |citation|
      citation.merge('used' => used.include?(citation['response_id'].to_s))
    end
  end

  private

  def ensure_account_and_conversation
    return if message.blank?

    self.account ||= message.account
    self.conversation ||= message.conversation
  end
end
