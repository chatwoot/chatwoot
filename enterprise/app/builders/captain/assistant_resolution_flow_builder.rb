# Builds the current-window resolution flow and its handoff-reason breakdown.
# The Sankey branches are mutually exclusive so their values remain balanced.
class Captain::AssistantResolutionFlowBuilder
  include Captain::AssistantOutcomeClassification

  PRIMARY_HANDOFF_REASON_COUNT = 2
  UNCLASSIFIED_REASON = 'unclassified'.freeze

  attr_reader :assistant, :account

  def initialize(assistant, range = Captain::AssistantStatsWindow::DEFAULT_RANGE, timezone_offset = nil)
    @assistant = assistant
    @account = assistant.account
    @window = Captain::AssistantStatsWindow.new(range, timezone_offset)
  end

  def build
    counts = flow_counts
    distribution = handoff_distribution(counts[:handed_off])

    {
      sankey: sankey(counts, distribution),
      handoff_distribution: distribution
    }
  end

  private

  attr_reader :window

  def flow_counts
    handled, autonomous, handoffs, reopened = outcomes_scope.reorder(nil).pick(
      filtered_count(involved(outcomes_table)),
      filtered_count(autonomous(outcomes_table)),
      filtered_count(handoff(outcomes_table)),
      filtered_count(reopened_within_7_days(outcomes_table))
    )

    {
      conversations_handled: handled,
      resolved_by_captain: autonomous,
      handed_off: handoffs,
      closed_with_team: handled - autonomous - handoffs,
      reopened_within_7_days: reopened,
      stayed_closed: autonomous - reopened
    }
  end

  def handoff_distribution(handoff_count)
    distribution = outcomes_scope.where(handoff(outcomes_table)).group(:handoff_reason_category).count.map do |category, count|
      {
        category: category || UNCLASSIFIED_REASON,
        count: count,
        percentage: percentage(count, handoff_count)
      }
    end

    distribution.sort_by { |entry| [-entry[:count], entry[:category]] }
  end

  def sankey(counts, distribution)
    reason_nodes, reason_links = sankey_handoff_reasons(distribution)

    {
      nodes: base_nodes(counts) + reason_nodes,
      links: base_links(counts) + reason_links
    }
  end

  def base_nodes(counts)
    counts.map { |id, count| { id: id, count: count } }
  end

  def base_links(counts)
    [
      link(:conversations_handled, :resolved_by_captain, counts[:resolved_by_captain]),
      link(:conversations_handled, :handed_off, counts[:handed_off]),
      link(:conversations_handled, :closed_with_team, counts[:closed_with_team]),
      link(:resolved_by_captain, :reopened_within_7_days, counts[:reopened_within_7_days]),
      link(:resolved_by_captain, :stayed_closed, counts[:stayed_closed])
    ]
  end

  def sankey_handoff_reasons(distribution)
    primary_reasons = distribution.first(PRIMARY_HANDOFF_REASON_COUNT)
    other_count = distribution.drop(PRIMARY_HANDOFF_REASON_COUNT).sum { |entry| entry[:count] }
    nodes = primary_reasons.map { |entry| reason_node(entry) }
    links = primary_reasons.map { |entry| link(:handed_off, reason_id(entry[:category]), entry[:count]) }

    if other_count.positive?
      nodes << { id: :other_reasons, count: other_count }
      links << link(:handed_off, :other_reasons, other_count)
    end

    [nodes, links]
  end

  def reason_node(entry)
    { id: reason_id(entry[:category]), count: entry[:count] }
  end

  def reason_id(category)
    "handoff_reason_#{category}".to_sym
  end

  def link(source, target, value)
    { source: source, target: target, value: value }
  end

  def percentage(count, total)
    return 0 if total.zero?

    (count.to_f / total * 100).round(1)
  end

  def outcomes_scope
    account.conversation_outcomes.where(assistant_id: assistant.id, started_at: window.current)
  end

  def filtered_count(predicate)
    Arel.star.count.filter(predicate)
  end

  def outcomes_table
    @outcomes_table ||= ConversationOutcome.arel_table
  end
end
