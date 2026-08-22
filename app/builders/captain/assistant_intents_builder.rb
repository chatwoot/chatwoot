# Surfaces the questions customers actually bring to a Captain assistant as
# "intents", and the resolution insight behind each one.
#
# An intent is a question the assistant was asked. We derive it from
# `captain_faq_observations`, which records the real customer question on each
# assistant turn. Observations already linked to an FAQ suggestion represent
# intents the assistant's knowledge covers; unmatched observations are new
# intents the knowledge base does not yet answer.
#
# Each intent carries a resolution breakdown (auto-resolved vs handed off vs
# still open) drawn from the conversation outcome recorded for this assistant on
# the same conversation, so the overview can show which intents the agent closes
# on its own and which it escalates.
class Captain::AssistantIntentsBuilder
  include Captain::AssistantOutcomeClassification

  DEFAULT_LIMIT = 10

  attr_reader :assistant, :account

  def initialize(assistant, range = Captain::AssistantStatsWindow::DEFAULT_RANGE, timezone_offset = nil, limit: DEFAULT_LIMIT)
    @assistant = assistant
    @account = assistant.account
    @window = Captain::AssistantStatsWindow.new(range, timezone_offset)
    @limit = limit
  end

  def build
    observations = scoped_observations
    return { total_intents: 0, total_questions: 0, intents: [] } if observations.empty?

    grouped = group_question_counts(observations)
    total_questions = grouped.sum { |entry| entry[:count] }

    # One outcome lookup per conversation keeps round trips flat regardless of
    # how many distinct intents share a conversation.
    outcomes_by_conversation = outcome_index(observations.map(&:conversation_id).uniq)

    intents = grouped.first(limit).map do |entry|
      resolution = resolution_for(entry[:conversation_ids], outcomes_by_conversation)
      entry.except(:observations, :conversation_ids).merge(resolution)
    end

    {
      total_intents: intents.length,
      total_questions: total_questions,
      intents: intents
    }
  end

  private

  attr_reader :window, :limit

  # Observations on this assistant in the window. An observation has no
  # assistant_id of its own, so the assistant scope comes from the conversation
  # outcome this assistant authored (its conversations). That link is a LEFT JOIN
  # with the scoping conditions in the ON clause, so observations without a
  # recorded outcome are still counted — resolution is fetched separately in
  # `outcome_index` and reported as "open" when absent.
  def scoped_observations
    outcome_join = ActiveRecord::Base.sanitize_sql_array(
      [
        'LEFT JOIN conversation_outcomes ON conversation_outcomes.conversation_id = conversations.id ' \
          'AND conversation_outcomes.assistant_id = ? ' \
          'AND conversation_outcomes.started_at BETWEEN ? AND ?',
        assistant.id, window.current.first, window.current.last
      ]
    )

    @scoped_observations ||= Captain::FaqObservation
                              .joins('INNER JOIN conversations ON conversations.id = captain_faq_observations.conversation_id')
                              .joins('LEFT JOIN captain_faq_suggestions ON captain_faq_suggestions.id = captain_faq_observations.faq_suggestion_id')
                              .joins(outcome_join)
                              .where(conversations: { account_id: account.id })
                              .where('captain_faq_observations.created_at BETWEEN ? AND ?', window.current.first, window.current.last)
                              .select(
                                'captain_faq_observations.id',
                                'captain_faq_observations.conversation_id',
                                'captain_faq_observations.generated_question',
                                'captain_faq_suggestions.question AS suggestion_question',
                                'captain_faq_suggestions.id AS suggestion_id'
                              )
                              .distinct
  end

  # Group by the canonical question: a matched FAQ's own question when present,
  # otherwise the raw generated question (a new, unmatched intent).
  def group_question_counts(observations)
    observations.group_by do |observation|
      if observation.suggestion_id.present?
        [:matched, observation.suggestion_id, observation.suggestion_question]
      else
        [:unmatched, observation.id, observation.generated_question]
      end
    end.map do |(_kind, _key, question), group|
      {
        question: question,
        count: group.length,
        conversations: group.map(&:conversation_id).uniq.length,
        matched: _kind == :matched,
        conversation_ids: group.map(&:conversation_id).uniq
      }
    end.sort_by { |entry| -entry[:count] }
  end

  def outcome_index(conversation_ids)
    return {} if conversation_ids.empty?

    assistant.conversation_outcomes
            .where(conversation_id: conversation_ids, started_at: window.current)
            .index_by(&:conversation_id)
  end

  # Resolution insight across the conversations that produced this intent.
  # An intent is auto-resolved only when every contributing conversation was
  # closed by the assistant without a handoff; a single handoff marks the intent
  # as escalated. Conversations still open are reported separately so the card
  # never overstates closure.
  def resolution_for(conversation_ids, outcomes_by_conversation)
    outcomes = conversation_ids.filter_map { |id| outcomes_by_conversation[id] }
    auto_resolved = outcomes.count(&:autonomous?)
    handed_off = outcomes.count(&:handoff?)
    open = conversation_ids.length - outcomes.length

    {
      auto_resolved: auto_resolved,
      handed_off: handed_off,
      open: open
    }
  end
end
