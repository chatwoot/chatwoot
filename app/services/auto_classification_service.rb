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
    return false if available_labels.empty? && available_teams.empty?

    true
  end

  def fetch_suggestions
    return nil if available_labels.empty? && available_teams.empty?

    ConversationTriageAgent.run(conversation)
  end

  def should_apply_label?
    conversation.label_list.empty? && available_labels.any?
  end

  def should_apply_team?
    conversation.team_id.nil? && available_teams.any?
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

  def available_labels
    @available_labels ||= account.labels.where(allow_auto_assign: true).as_json(only: [:id, :title, :description])
  end

  def available_teams
    @available_teams ||= account.teams.where(allow_auto_assign: true).as_json(only: [:id, :name, :description])
  end
end
