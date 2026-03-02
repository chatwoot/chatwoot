# frozen_string_literal: true

class Conversations::AutoAssignService
  MIN_CONTENT_LENGTH = 60
  MIN_CONTENT_LENGTH_MULTI = 30
  MIN_MESSAGES_MULTI = 2
  MAX_AUTO_LABELS = 2

  attr_reader :conversation, :account, :labels, :teams

  def initialize(conversation)
    @conversation = conversation
    @account = conversation.account
    @labels = account.labels.with_auto_assign_enabled.as_json(only: [:id, :title, :description])
    @teams = account.teams.with_auto_assign_enabled.as_json(only: [:id, :name, :description])
  end

  def perform
    return unless should_process?

    with_context do
      conversation.update_column(:last_triaged_at, Time.current) # rubocop:disable Rails/SkipsModelValidations

      suggestions = fetch_suggestions
      apply_suggestions(suggestions) if suggestions
    end
  rescue StandardError => e
    Rails.logger.error("Auto-classification failed for conversation #{conversation.id}: #{e.message}")
    raise
  end

  private

  def with_context
    Aloo::Current.account = account
    yield
  ensure
    Aloo::Current.reset
  end

  def should_process?
    conversation.open? && threshold_met? && !recently_triaged? && has_auto_assign_options? && needs_assignment?
  end

  def has_auto_assign_options? # rubocop:disable Naming/PredicateName
    labels.any? || teams.any?
  end

  def needs_assignment?
    should_apply_label? || should_apply_team?
  end

  def apply_suggestions(suggestions)
    suggestions = suggestions.with_indifferent_access if suggestions.is_a?(Hash)
    apply_labels(suggestions['label_ids']) if suggestions['label_ids'].present? && should_apply_label?
    apply_team(suggestions['team_id']) if suggestions['team_id'].present? && should_apply_team?
  end

  def recently_triaged?
    return false if conversation.last_triaged_at.nil?

    conversation.last_triaged_at > 30.minutes.ago && !new_messages_since_triage?
  end

  def new_messages_since_triage?
    conversation.messages.incoming.exists?(['created_at > ?', conversation.last_triaged_at])
  end

  def threshold_met?
    incoming = conversation.messages.incoming
    message_count = incoming.count
    return false if message_count.zero?

    total_length = incoming.sum("LENGTH(COALESCE(content, ''))")

    return true if message_count == 1 && total_length >= MIN_CONTENT_LENGTH
    return true if message_count >= MIN_MESSAGES_MULTI && total_length >= MIN_CONTENT_LENGTH_MULTI

    false
  end

  def should_apply_label?
    conversation.label_list.size < MAX_AUTO_LABELS
  end

  def should_apply_team?
    conversation.team_id.nil?
  end

  def fetch_suggestions
    conversation_messages = conversation.messages.last(20).map do |msg|
      { incoming: msg.incoming?, content: msg.content }
    end

    result = ConversationTriageAgent.call(
      conversation_messages: conversation_messages,
      available_labels: labels,
      available_teams: teams,
      account_id: account.id,
      conversation_id: conversation.id,
      inbox_id: conversation.inbox_id
    )

    return nil unless result.success?

    result.content
  end

  def apply_labels(label_ids)
    label_ids = Array(label_ids).compact.uniq
    return if label_ids.empty?

    current_count = conversation.label_list.size
    slots_available = MAX_AUTO_LABELS - current_count
    return if slots_available <= 0

    labels_to_add = account.labels.where(id: label_ids.first(slots_available))
    return if labels_to_add.empty?

    titles = labels_to_add.map(&:title)
    conversation.add_labels(titles)
    Rails.logger.info("Auto-labeled conversation #{conversation.id} with: #{titles.join(', ')}")
  end

  def apply_team(team_id)
    team = account.teams.find_by(id: team_id)
    return unless team

    conversation.update(team: team)
    Rails.logger.info("Auto-assigned conversation #{conversation.id} to team: #{team.name}")
  end
end
