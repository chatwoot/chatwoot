# frozen_string_literal: true

class Api::V1::Accounts::Aloo::VoiceUsageController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  SYNTHESIS_AGENTS = %w[Audio::AlooSpeaker Audio::AlooOpenaiSpeaker].freeze
  TRANSCRIPTION_AGENTS = %w[Audio::AlooTranscriber].freeze
  AUDIO_AGENTS = (SYNTHESIS_AGENTS + TRANSCRIPTION_AGENTS).freeze

  # GET /api/v1/accounts/:account_id/aloo/voice_usage
  def show
    period_start = parse_date_param(:period_start, Time.current.beginning_of_month)
    period_end = parse_date_param(:period_end, Time.current.end_of_month)

    usage = executions_scope.where(started_at: period_start..period_end)

    render json: {
      period: { start: period_start.iso8601, end: period_end.iso8601 },
      transcription: build_transcription_stats(usage),
      synthesis: build_synthesis_stats(usage),
      total_estimated_cost: usage.successful.sum(:total_cost).to_f.round(4),
      failed_operations: usage.failed.count,
      by_assistant: build_assistant_breakdown(usage),
      daily_breakdown: build_daily_breakdown(usage)
    }
  end

  # GET /api/v1/accounts/:account_id/aloo/voice_usage/summary
  def summary
    current_month = executions_scope.where(started_at: Time.current.all_month)
    last_month = executions_scope.where(started_at: 1.month.ago.all_month)

    render json: {
      current_month: month_summary(current_month),
      last_month: month_summary(last_month),
      quota: build_quota_info
    }
  end

  private

  def executions_scope
    RubyLLM::Agents::Execution
      .by_tenant(Current.account.id.to_s)
      .where(agent_type: AUDIO_AGENTS)
  end

  def month_summary(scope)
    {
      transcription_count: scope.successful.where(agent_type: TRANSCRIPTION_AGENTS).count,
      synthesis_count: scope.successful.where(agent_type: SYNTHESIS_AGENTS).count,
      total_cost: scope.successful.sum(:total_cost).to_f.round(4)
    }
  end

  def build_transcription_stats(usage)
    stats = usage.successful.where(agent_type: TRANSCRIPTION_AGENTS)
    {
      count: stats.count,
      total_duration_seconds: stats.sum(:duration_ms).to_i / 1000,
      total_duration_minutes: (stats.sum(:duration_ms).to_f / 60_000).round(2),
      estimated_cost: stats.sum(:total_cost).to_f.round(4)
    }
  end

  def build_synthesis_stats(usage)
    stats = usage.successful.where(agent_type: SYNTHESIS_AGENTS)
    {
      count: stats.count,
      total_characters: stats.sum(:input_tokens),
      estimated_cost: stats.sum(:total_cost).to_f.round(4)
    }
  end

  def build_assistant_breakdown(usage)
    Current.account.aloo_assistants.map do |assistant|
      assistant_usage = usage.metadata_value('aloo_assistant_id', assistant.id.to_s)
      {
        id: assistant.id,
        name: assistant.name,
        transcription_count: assistant_usage.successful.where(agent_type: TRANSCRIPTION_AGENTS).count,
        synthesis_count: assistant_usage.successful.where(agent_type: SYNTHESIS_AGENTS).count,
        total_cost: assistant_usage.successful.sum(:total_cost).to_f.round(4)
      }
    end
  end

  def build_daily_breakdown(usage)
    daily_breakdown_query(usage).map { |record| format_daily_record(record) }
  end

  def daily_breakdown_query(usage)
    usage.successful
         .group('DATE(started_at)', :agent_type)
         .select(
           'DATE(started_at) as date', 'agent_type', 'COUNT(*) as count',
           'SUM(input_tokens) as characters', 'SUM(duration_ms) as duration_ms_total',
           'SUM(total_cost) as cost'
         )
  end

  def format_daily_record(record)
    {
      date: record.date,
      type: SYNTHESIS_AGENTS.include?(record.agent_type) ? 'synthesis' : 'transcription',
      count: record.count, characters: record.characters.to_i,
      duration: (record.duration_ms_total.to_i / 1000), cost: record.cost.to_f.round(4)
    }
  end

  def build_quota_info
    tenant = RubyLLM::Agents::Tenant.find_by(tenant_id: Current.account.id.to_s)
    daily_limit = tenant&.daily_limit&.to_f || 50.0

    used_today = executions_scope
                 .successful
                 .where(started_at: Time.current.all_day)
                 .sum(:total_cost).to_f

    {
      daily_limit: daily_limit,
      used_today: used_today.round(4),
      remaining: [daily_limit - used_today, 0].max.round(4),
      percentage_used: daily_limit.positive? ? ((used_today / daily_limit) * 100).round(2) : 0
    }
  end

  def parse_date_param(param_name, default)
    return default if params[param_name].blank?

    Time.zone.parse(params[param_name])
  rescue ArgumentError
    default
  end

  def check_authorization
    authorize(Current.account, :update?)
  end
end
