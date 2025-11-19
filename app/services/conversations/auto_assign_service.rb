# frozen_string_literal: true

class Conversations::AutoAssignService
  attr_reader :conversation, :account, :labels, :teams

  def initialize(conversation)
    @conversation = conversation
    @account = conversation.account
    @labels = account.labels.with_auto_assign_enabled.as_json(only: [:id, :title, :description])
    @teams = account.teams.with_auto_assign_enabled.as_json(only: [:id, :name, :description])
  end

  def perform
    return unless should_process?

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
    return false unless threshold_met?
    return if labels.empty? && teams.empty?

    true
  end

  def threshold_met?
    threshold = 3
    conversation.messages.incoming.count >= threshold
  end

  def should_apply_label?
    conversation.label_list.empty?
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
