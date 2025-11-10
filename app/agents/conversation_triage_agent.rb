# frozen_string_literal: true

class ConversationTriageAgent < BaseAgent
  MODEL = 'gpt-4o-mini'
  TEMPERATURE = 0.3

  def initialize(conversation)
    @conversation = conversation
    @account = conversation.account
    @available_labels = @account.labels.where(allow_auto_assign: true)
    @available_teams = @account.teams.where(allow_auto_assign: true)
  end

  def run
    return nil if @available_labels.empty? && @available_teams.empty?

    execute
  rescue StandardError => e
    log_error('Conversation triage failed', e)
    nil
  end

  def user_prompt
    prompt = <<~PROMPT
      You are a customer support conversation triage assistant. Your task is to analyze the conversation
      and suggest the most appropriate label and team assignment.

    PROMPT

    # Add labels section if available
    if @available_labels.any?
      labels_list = @available_labels.map do |label|
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
    if @available_teams.any?
      teams_list = @available_teams.map do |team|
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
