# frozen_string_literal: true

class Conversations::AutoAssignService
  attr_reader :conversation, :account

  def initialize(conversation)
    @conversation = conversation
    @account = conversation.account
  end

  def perform
    suggestions = fetch_suggestions
    return if suggestions.nil?

    apply_label(suggestions['label_id']) if suggestions['label_id'].present?
    apply_team(suggestions['team_id']) if suggestions['team_id'].present?
  rescue StandardError => e
    Rails.logger.error("Auto-classification failed for conversation #{conversation.id}: #{e.message}")
    raise # Re-raise for job retry
  end

  private

  def fetch_suggestions
    ConversationTriageAgent.run(conversation)
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
