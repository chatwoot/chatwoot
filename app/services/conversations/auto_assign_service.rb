# frozen_string_literal: true

class Conversations::AutoAssignService
  attr_reader :conversation, :account, :labels, :teams

  def initialize(conversation)
    @conversation = conversation
    @account = conversation.account
    existing_labels = conversation.label_list.map(&:downcase)
    @labels = account.labels
                     .with_auto_assign_enabled
                     .where.not('LOWER(title) IN (?)', existing_labels.presence || [''])
                     .as_json(only: [:id, :title, :description])
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
    raise # Re-raise for job retry
  end

  private

  def should_process?
    return false unless conversation.open?
    return false if stale_conversation?
    return false unless threshold_met?
    return false if recently_triaged?
    return if labels.empty? && teams.empty?

    true
  end

  def stale_conversation?
    last_message = conversation.messages.last
    return true if last_message.nil?

    last_message.created_at < 1.hour.ago
  end

  def recently_triaged?
    return false if conversation.last_triaged_at.nil?

    conversation.last_triaged_at > 30.minutes.ago
  end

  def threshold_met?
    message_threshold = 3
    time_threshold = 5.minutes

    # 3+ messages always triggers
    return true if conversation.messages.incoming.count >= message_threshold

    # 5-minute threshold only applies if conversation has no labels
    conversation.label_list.empty? && conversation.created_at <= time_threshold.ago
  end

  def should_apply_label?
    max_auto_labels = 3
    conversation.label_list.size < max_auto_labels
  end

  def should_apply_team?
    conversation.team_id.nil?
  end

  def fetch_suggestions
    ConversationTriageAgent.run(conversation: conversation, teams: teams, labels: labels)
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
