# frozen_string_literal: true

class Conversations::AutoAssignService
  MIN_MESSAGES = 3
  MAX_MESSAGES = 10

  attr_reader :conversation, :account, :labels, :teams

  def initialize(conversation)
    @conversation = conversation
    @account = conversation.account
    @labels = account.labels.with_auto_assign_enabled.as_json(only: [:id, :title, :description])
    @teams = account.teams.with_auto_assign_enabled.as_json(only: [:id, :name, :description])
  end

  def perform
    return unless should_process?

    conversation.update_column(:last_triaged_at, Time.current)

    suggestions = fetch_suggestions
    return if suggestions.nil?

    apply_label(suggestions['label_id']) if suggestions['label_id'].present? && should_apply_label?
    apply_team(suggestions['team_id']) if suggestions['team_id'].present? && should_apply_team?
  rescue StandardError => e
    Rails.logger.error("Auto-classification failed for conversation #{conversation.id}: #{e.message}")
    raise
  end

  private

  def should_process?
    return false unless conversation.open?
    return false unless threshold_met?
    return false if recently_triaged?
    return false if labels.empty? && teams.empty?

    true
  end

  def recently_triaged?
    return false if conversation.last_triaged_at.nil?

    conversation.last_triaged_at > 30.minutes.ago
  end

  def threshold_met?
    message_threshold = 3
    time_threshold = 5.minutes

    message_count = conversation.messages.incoming.count
    conversation_age = Time.current - conversation.created_at

    message_count >= message_threshold || (conversation_age >= time_threshold && conversation.label_list.empty?)
  end

  def should_apply_label?
    conversation.label_list.empty?
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
      available_teams: teams
    )

    return nil unless result.success?

    result.content
  end

  def apply_label(label_id)
    label = account.labels.find_by(id: label_id)
    return unless label

    conversation.add_labels([label.title])
    Rails.logger.info("Auto-labeled conversation #{conversation.id} with: #{label.title}")
  end

  def apply_team(team_id)
    team = account.teams.find_by(id: team_id)
    return unless team

    conversation.update(team: team)
    Rails.logger.info("Auto-assigned conversation #{conversation.id} to team: #{team.name}")
  end
end
