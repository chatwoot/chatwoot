# frozen_string_literal: true

class Api::V1::Accounts::Aloo::AssistantsController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :set_assistant, except: %i[index create check_name]

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

  # GET /api/v1/accounts/:account_id/aloo/assistants/check_name
  def check_name
    exists = Current.account.aloo_assistants.exists?(name: params[:name])
    render json: { available: !exists }
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

  # GET /api/v1/accounts/:account_id/aloo/assistants/:id/voices
  # List available ElevenLabs voices
  def voices
    client = elevenlabs_client
    return render json: { error: 'ElevenLabs API key not configured' }, status: :service_unavailable unless client

    voices_data = client.list_voices
    render json: {
      voices: voices_data.map do |v|
        {
          voice_id: v['voice_id'],
          name: v['name'],
          category: v['category'],
          description: v['description'],
          preview_url: v['preview_url'],
          labels: v['labels']
        }
      end
    }
  rescue Aloo::ElevenlabsClient::Error => e
    render json: { error: e.message }, status: :service_unavailable
  end

  # POST /api/v1/accounts/:account_id/aloo/assistants/:id/preview_voice
  # Generate sample audio with selected voice settings (bypasses voice_enabled check for preview)
  def preview_voice
    text = params[:text].presence || 'Hello, this is a voice preview for the Aloo AI assistant.'
    voice_id = params[:voice_id].presence || @assistant.elevenlabs_voice_id

    return render json: { error: 'voice_id is required' }, status: :unprocessable_entity if voice_id.blank?

    # Use ElevenlabsClient directly for preview (bypasses assistant voice config check)
    client = Aloo::ElevenlabsClient.new
    audio_data = client.text_to_speech(
      text: text,
      voice_id: voice_id,
      model_id: @assistant.effective_tts_model
    )

    send_data audio_data,
              type: 'audio/mpeg',
              disposition: 'inline',
              filename: 'preview.mp3'
  rescue Aloo::ElevenlabsClient::Error => e
    render json: { error: e.message }, status: :service_unavailable
  end

  # GET /api/v1/accounts/:account_id/aloo/assistants/:id/voice_usage
  # Get voice usage statistics for this assistant
  def voice_usage
    period_start = parse_date_param(:period_start, Time.current.beginning_of_month)
    period_end = parse_date_param(:period_end, Time.current.end_of_month)

    usage = @assistant.voice_usage_records.for_period(period_start, period_end)

    transcription_stats = usage.transcriptions.successful
    synthesis_stats = usage.synthesis.successful

    render json: {
      period: { start: period_start.iso8601, end: period_end.iso8601 },
      transcription: {
        count: transcription_stats.count,
        total_duration_seconds: transcription_stats.sum(:audio_duration_seconds),
        estimated_cost: transcription_stats.sum(:estimated_cost).to_f.round(4)
      },
      synthesis: {
        count: synthesis_stats.count,
        total_characters: synthesis_stats.sum(:characters_used),
        estimated_cost: synthesis_stats.sum(:estimated_cost).to_f.round(4)
      },
      total_estimated_cost: usage.successful.sum(:estimated_cost).to_f.round(4),
      failed_operations: usage.failed.count
    }
  end

  # POST /api/v1/accounts/:account_id/aloo/assistants/:id/playground
  # Test the assistant with a message without creating a real conversation
  def playground
    message = params.require(:message)

    # Set up Aloo context for the agent
    Aloo::Current.account = Current.account
    Aloo::Current.assistant = @assistant
    Aloo::Current.request_id = SecureRandom.uuid

    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    result = ConversationAgent.call(
      message: message,
      conversation_history: params[:conversation_history]
    )

    duration_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000).round

    render json: {
      response: result.content,
      success: result.success?,
      input_tokens: result.input_tokens,
      output_tokens: result.output_tokens,
      total_tokens: (result.input_tokens || 0) + (result.output_tokens || 0),
      duration_ms: duration_ms,
      tool_calls: result.tool_calls&.map { |tc| { name: tc.name, arguments: tc.arguments } }
    }
  rescue RubyLLM::Error => e
    render json: { error: e.message, success: false }, status: :unprocessable_entity
  ensure
    Aloo::Current.reset
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
      :personality_description,
      :voice_enabled,
      :voice_input_enabled,
      :voice_output_enabled,
      voice_config: %i[
        transcription_provider
        transcription_model
        tts_provider
        elevenlabs_voice_id
        elevenlabs_model_id
        elevenlabs_stability
        elevenlabs_similarity_boost
        reply_mode
      ],
      admin_config: %i[
        feature_handoff
        feature_resolve
        feature_snooze
        feature_labels
      ]
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
        faq_enabled: assistant.feature_faq_enabled?,
        handoff_enabled: assistant.feature_handoff_enabled?,
        resolve_enabled: assistant.feature_resolve_enabled?,
        snooze_enabled: assistant.feature_snooze_enabled?,
        labels_enabled: assistant.feature_labels_enabled?
      },
      voice: {
        enabled: assistant.voice_enabled?,
        input_enabled: assistant.voice_input_enabled?,
        output_enabled: assistant.voice_output_enabled?,
        config: assistant.voice_config || {},
        transcription_enabled: assistant.voice_transcription_enabled?,
        reply_enabled: assistant.voice_reply_enabled?
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

  def parse_date_param(param_name, default)
    return default if params[param_name].blank?

    Time.zone.parse(params[param_name])
  rescue ArgumentError
    default
  end

  def elevenlabs_client
    api_key = Current.account.custom_attributes&.dig('elevenlabs_api_key') ||
              InstallationConfig.find_by(name: 'ELEVENLABS_API_KEY')&.value ||
              ENV.fetch('ELEVENLABS_API_KEY', nil)

    return nil if api_key.blank?

    Aloo::ElevenlabsClient.new(api_key: api_key)
  end
end
