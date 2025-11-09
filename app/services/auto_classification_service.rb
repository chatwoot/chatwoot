# frozen_string_literal: true

class AutoClassificationService
  attr_reader :conversation, :account

  def initialize(conversation)
    @conversation = conversation
    @account = conversation.account
  end

  def perform
    return unless should_classify?

    suggestions = fetch_suggestions
    return if suggestions.nil?

    apply_label(suggestions['label_id']) if should_apply_label? && suggestions['label_id'].present?
    apply_team(suggestions['team_id']) if should_apply_team? && suggestions['team_id'].present?
  rescue StandardError => e
    Rails.logger.error("Auto-classification failed for conversation #{conversation.id}: #{e.message}")
    raise # Re-raise for job retry
  end

  private

  def should_classify?
    return false unless auto_label_enabled? || auto_team_enabled?
    return false unless message_threshold_met?

    true
  end

  def message_threshold_met?
    threshold = account.settings.fetch('auto_label_message_threshold', 3)
    conversation.messages.incoming.count >= threshold
  end

  def fetch_suggestions
    labels = auto_label_enabled? ? available_labels : []
    teams = auto_team_enabled? ? available_teams : []

    return nil if labels.empty? && teams.empty?

    ConversationTriageAgent.run(conversation)
  end

  def should_apply_label?
    auto_label_enabled? && conversation.label_list.empty?
  end

  def should_apply_team?
    auto_team_enabled? && conversation.team_id.nil?
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

  def auto_label_enabled?
    account.settings.dig('auto_label_enabled') == true
  end

  def auto_team_enabled?
    account.settings.dig('auto_team_enabled') == true
  end

  def available_labels
    @available_labels ||= account.labels.as_json(only: [:id, :title, :description])
  end

  def available_teams
    @available_teams ||= account.teams.as_json(only: [:id, :name, :description])
  end
end
