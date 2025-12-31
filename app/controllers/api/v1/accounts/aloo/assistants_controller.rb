# frozen_string_literal: true

class Api::V1::Accounts::Aloo::AssistantsController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :set_assistant, except: %i[index create]

  def index
    @assistants = Current.account.aloo_assistants.order(:name)
    render json: {
      payload: @assistants.map { |a| assistant_json(a) },
      meta: { total_count: @assistants.count }
    }
  end

  def show
    render json: assistant_json(@assistant)
  end

  def create
    @assistant = Current.account.aloo_assistants.create!(assistant_params)
    render json: assistant_json(@assistant), status: :created
  end

  def update
    @assistant.update!(assistant_params)
    render json: assistant_json(@assistant)
  end

  def destroy
    @assistant.destroy!
    head :ok
  end

  # GET /api/v1/accounts/:account_id/aloo/assistants/:id/stats
  def stats
    render json: {
      total_conversations: @assistant.conversation_contexts.count,
      total_messages: @assistant.conversation_contexts.sum(:message_count),
      total_tokens: @assistant.conversation_contexts.sum('input_tokens + output_tokens'),
      total_memories: @assistant.memories.active.count,
      total_documents: @assistant.documents.available.count
    }
  end

  # GET /api/v1/accounts/:account_id/aloo/assistants/:id/performance
  def performance
    time_range = parse_time_range(params[:range] || '7d')

    contexts = @assistant.conversation_contexts.where('created_at >= ?', time_range)
    traces = @assistant.traces.where('created_at >= ?', time_range)

    total_conversations = contexts.count
    successful_responses = traces.successful.by_type('agent_call').count
    failed_responses = traces.failed.by_type('agent_call').count
    total_responses = successful_responses + failed_responses

    # Calculate average response time from traces
    avg_response_time = traces.by_type('agent_call').average(:duration_ms)&.round(2) || 0

    # Calculate handoff rate (conversations that required human handoff)
    # Assuming handoff is tracked in context_data or via a custom attribute
    handoff_count = contexts.where("context_data->>'handoff_triggered' = ?", 'true').count
    handoff_rate = total_conversations.positive? ? (handoff_count.to_f / total_conversations * 100).round(2) : 0

    # Token usage
    total_input_tokens = contexts.sum(:input_tokens)
    total_output_tokens = contexts.sum(:output_tokens)

    render json: {
      response_rate: total_responses.positive? ? (successful_responses.to_f / total_responses * 100).round(2) : 100,
      avg_response_time_ms: avg_response_time,
      handoff_rate: handoff_rate,
      total_conversations: total_conversations,
      token_usage: {
        total_input: total_input_tokens,
        total_output: total_output_tokens,
        total: total_input_tokens + total_output_tokens
      },
      memory_stats: {
        total: @assistant.memories.count,
        active: @assistant.memories.active.count,
        by_type: @assistant.memories.group(:memory_type).count
      },
      time_range: params[:range] || '7d'
    }
  end

  # POST /api/v1/accounts/:account_id/aloo/assistants/:id/assign_inbox
  def assign_inbox
    inbox = Current.account.inboxes.find(params[:inbox_id])

    # Remove existing assignment if any
    Aloo::AssistantInbox.find_by(inbox: inbox)&.destroy

    # Create new assignment
    Aloo::AssistantInbox.create!(
      assistant: @assistant,
      inbox: inbox,
      active: true
    )

    render json: { message: 'Assistant assigned to inbox' }
  end

  # DELETE /api/v1/accounts/:account_id/aloo/assistants/:id/unassign_inbox
  def unassign_inbox
    inbox = Current.account.inboxes.find(params[:inbox_id])
    Aloo::AssistantInbox.find_by(assistant: @assistant, inbox: inbox)&.destroy
    render json: { message: 'Assistant unassigned from inbox' }
  end

  private

  def set_assistant
    @assistant = Current.account.aloo_assistants.find(params[:id])
  end

  def assistant_params
    params.require(:assistant).permit(
      :name,
      :description,
      :active,
      :language,
      :dialect,
      :tone,
      :formality,
      :empathy_level,
      :verbosity,
      :emoji_usage,
      :greeting_style,
      :custom_greeting,
      :personality_description
    )
  end

  def assistant_json(assistant)
    {
      id: assistant.id,
      name: assistant.name,
      description: assistant.description,
      active: assistant.active,
      language: assistant.language,
      dialect: assistant.dialect,
      personality: {
        tone: assistant.tone,
        formality: assistant.formality,
        empathy_level: assistant.empathy_level,
        verbosity: assistant.verbosity,
        emoji_usage: assistant.emoji_usage,
        greeting_style: assistant.greeting_style,
        custom_greeting: assistant.custom_greeting,
        personality_description: assistant.personality_description
      },
      features: {
        memory_enabled: assistant.feature_memory_enabled?,
        faq_enabled: assistant.feature_faq_enabled?
      },
      assigned_inboxes: assistant.inboxes.map { |i| { id: i.id, name: i.name } },
      created_at: assistant.created_at,
      updated_at: assistant.updated_at
    }
  end

  def check_authorization
    authorize(Current.account, :update?)
  end

  def parse_time_range(range)
    case range
    when '24h' then 24.hours.ago
    when '7d' then 7.days.ago
    when '30d' then 30.days.ago
    when '90d' then 90.days.ago
    else 7.days.ago
    end
  end
end
