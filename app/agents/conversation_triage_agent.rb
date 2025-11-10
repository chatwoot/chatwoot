# frozen_string_literal: true

class ConversationTriageAgent < BaseAgent
  MODEL = 'gpt-4o-mini'
  TEMPERATURE = 0.3

  def initialize(conversation:, teams: [], labels: [])
    @conversation = conversation
    @teams = teams
    @labels = labels
  end

  def run
    return nil if @labels.empty? && @teams.empty?

    execute
  end

  def user_prompt
    prompt = <<~PROMPT
      You are a customer support conversation triage assistant. Your task is to analyze the conversation
      and suggest the most appropriate label and team assignment.

    PROMPT

    # Add labels section if available
    if @labels.any?
      labels_list = @labels.map do |label|
        desc = label['description'].present? ? " - #{label['description']}" : ''
        "#{label['id']}: #{label['title']}#{desc}"
      end.join("\n")

      prompt += <<~LABELS
        Available Labels:
        #{labels_list}

        Select the SINGLE most relevant label ID, or null if none fit.

      LABELS
    end

    # Add teams section if available
    if @teams.any?
      teams_list = @teams.map do |team|
        desc = team['description'].present? ? " - #{team['description']}" : ''
        "#{team['id']}: #{team['name']}#{desc}"
      end.join("\n")

      prompt += <<~TEAMS
        Available Teams:
        #{teams_list}

        Select the SINGLE most appropriate team ID, or null if none fit.

      TEAMS
    end

    prompt += <<~RULES
      Rules:
      - Base decisions on conversation content and context
      - IDs must be from the lists above
      - Return null for label_id or team_id if no good match exists

      Conversation:
    RULES

    # Add conversation messages (last 20)
    @conversation.messages.last(20).each do |message|
      sender = message.incoming? ? 'Customer' : 'Agent'
      prompt += "\n#{sender}: #{message.content}"
    end

    prompt
  end

  def schema
    RubyLLM::Schema.create do
      integer :label_id, description: 'The ID of the most relevant label from the available labels list, or null if none fit'
      integer :team_id, description: 'The ID of the most appropriate team from the available teams list, or null if none fit'
    end
  end
end
