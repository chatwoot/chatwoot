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
  description 'Analyzes conversations and suggests appropriate labels/team assignments'
  model 'gpt-4.1-mini'
  temperature 0.2

  on_failure do
    fallback to: ['gemini-2.5-flash', 'gpt-4.1-nano']
  end

  param :conversation_messages, required: true
  param :available_labels
  param :available_teams
  param :account_id
  param :conversation_id
  param :inbox_id

  def metadata
    {
      account_id: account_id&.to_s,
      conversation_id: conversation_id&.to_s,
      inbox_id: inbox_id&.to_s,
      message_count: conversation_messages&.size&.to_s
    }.compact
  end

  def system_prompt
    <<~PROMPT
      You are an expert customer support triage classifier.

      Your task is to analyze customer conversations and assign the most accurate labels and team routing based on the PRIMARY intent of the conversation.

      Classification rules:
      - Focus on the customer's core issue, not tangential mentions
      - If the conversation is ambiguous, prefer the label that best matches the customer's most recent message
      - Only assign a label if you are confident it applies
      - Prefer fewer, more accurate labels over more labels
      - Return empty/null when no good match exists — do not force-fit
    PROMPT
  end

  def user_prompt
    build_triage_prompt
  end

  returns do
    string :reasoning, description: 'Brief explanation of why these labels/team were chosen (1-2 sentences)'
    array :label_ids, of: :integer, max_items: 2,
                      description: 'Up to 2 most relevant label IDs, or empty array if none fit'
    integer :team_id, description: 'The ID of the most appropriate team, or null if none fit'
  end

  private

  def build_triage_prompt
    prompt = +''
    prompt << labels_section if available_labels&.any?
    prompt << teams_section if available_teams&.any?
    prompt << rules_section
    prompt << messages_section
    prompt
  end

  def labels_section
    labels_list = available_labels.map do |label|
      desc = label['description'].present? ? " — #{label['description']}" : ''
      "- ID #{label['id']}: #{label['title']}#{desc}"
    end.join("\n")

    <<~LABELS
      Available Labels:
      #{labels_list}

      Select up to 2 most relevant label IDs. Only select a label if the conversation clearly relates to it. Return an empty array if none fit well.

    LABELS
  end

  def teams_section
    teams_list = available_teams.map do |team|
      desc = team['description'].present? ? " — #{team['description']}" : ''
      "- ID #{team['id']}: #{team['name']}#{desc}"
    end.join("\n")

    <<~TEAMS
      Available Teams:
      #{teams_list}

      Select the SINGLE most appropriate team ID, or null if none fit.

    TEAMS
  end

  def rules_section
    <<~RULES
      Decision Guidelines:
      - Identify the PRIMARY topic of the conversation first
      - If multiple topics exist, prioritize the customer's most recent concern
      - Only assign labels you are confident about — partial matches should be skipped
      - For team routing, match based on which team's description best fits the core issue
      - IDs must come from the lists above — never invent IDs

      Conversation to analyze:
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
