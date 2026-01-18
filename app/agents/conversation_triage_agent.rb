# frozen_string_literal: true

# Analyzes conversations and suggests appropriate labels/team assignments
#
# Example:
#   ConversationTriageAgent.call(
#     conversation_messages: [{ incoming: true, content: "..." }],
#     available_labels: [{ id: 1, title: "Bug", description: "..." }],
#     available_teams: [{ id: 1, name: "Support", description: "..." }]
#   )
#
class ConversationTriageAgent < ApplicationAgent
  description 'Analyzes conversations and suggests appropriae labels/team assignments'
  model 'gemini-2.5-flash-lite'
  temperature 0.3
  version '1.0'

  reliability do
    fallback_models ['gpt-4.1-nano', 'claude-haiku-4-5']
  end

  param :conversation_messages, required: true
  param :available_labels
  param :available_teams

  def user_prompt
    build_triage_prompt
  end

  def schema
    RubyLLM::Schema.create do
      integer :label_id, description: 'The ID of the most relevant label, or null if none fit'
      integer :team_id, description: 'The ID of the most appropriate team, or null if none fit'
    end
  end

  private

  def build_triage_prompt
    prompt = <<~PROMPT
      You are a customer support conversation triage assistant. Your task is to analyze the conversation
      and suggest the most appropriate label and team assignment.

    PROMPT

    prompt += labels_section if available_labels&.any?
    prompt += teams_section if available_teams&.any?
    prompt += rules_section
    prompt += messages_section

    prompt
  end

  def labels_section
    labels_list = available_labels.map do |label|
      desc = label['description'].present? ? " - #{label['description']}" : ''
      "#{label['id']}: #{label['title']}#{desc}"
    end.join("\n")

    <<~LABELS
      Available Labels:
      #{labels_list}

      Select the SINGLE most relevant label ID, or null if none fit.

    LABELS
  end

  def teams_section
    teams_list = available_teams.map do |team|
      desc = team['description'].present? ? " - #{team['description']}" : ''
      "#{team['id']}: #{team['name']}#{desc}"
    end.join("\n")

    <<~TEAMS
      Available Teams:
      #{teams_list}

      Select the SINGLE most appropriate team ID, or null if none fit.

    TEAMS
  end

  def rules_section
    <<~RULES
      Rules:
      - Base decisions on conversation content and context
      - IDs must be from the lists above
      - Return null for label_id or team_id if no good match exists

      Conversation:
    RULES
  end

  def messages_section
    conversation_messages.map do |msg|
      sender = msg[:incoming] || msg['incoming'] ? 'Customer' : 'Agent'
      content = msg[:content] || msg['content']
      "\n#{sender}: #{content}"
    end.join
  end
end
