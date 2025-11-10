# frozen_string_literal: true

class Conversations::AutoAssignService
  attr_reader :conversation, :account

  def initialize(conversation)
    @conversation = conversation
    @account = conversation.account
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
    return false unless auto_label_enabled? || auto_team_enabled?
    return false unless threshold_met?

    true
  end

  def auto_label_enabled?
    account.settings['auto_label_enabled'] == true
  end

  def auto_team_enabled?
    account.settings['auto_team_enabled'] == true
  end

  def threshold_met?
    threshold = account.settings['auto_label_message_threshold'] || 3
    conversation.messages.incoming.count >= threshold
  end

  def should_apply_label?
    conversation.label_list.empty?
  end

  def should_apply_team?
    conversation.team_id.nil?
  end

  def fetch_suggestions
    options = {
      available_labels: auto_label_enabled? ? available_labels : [],
      available_teams: auto_team_enabled? ? available_teams : []
    }
    ConversationTriageAgent.run(conversation, options)
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
