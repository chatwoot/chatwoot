# frozen_string_literal: true

class Api::V1::Accounts::Aloo::VoiceUsageController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  # GET /api/v1/accounts/:account_id/aloo/voice_usage
  # Returns account-wide voice usage statistics
  def index
    period_start = parse_date_param(:period_start, Time.current.beginning_of_month)
    period_end = parse_date_param(:period_end, Time.current.end_of_month)

    usage = Aloo::VoiceUsageRecord
            .where(account: Current.account)
            .for_period(period_start, period_end)

    render json: {
      period: { start: period_start.iso8601, end: period_end.iso8601 },
      transcription: build_transcription_stats(usage),
      synthesis: build_synthesis_stats(usage),
      total_estimated_cost: usage.successful.sum(:estimated_cost).to_f.round(4),
      failed_operations: usage.failed.count,
      by_assistant: build_assistant_breakdown(usage),
      daily_breakdown: build_daily_breakdown(usage)
    }
  end

  # GET /api/v1/accounts/:account_id/aloo/voice_usage/summary
  # Returns a quick summary for dashboard widgets
  def summary
    current_month = Aloo::VoiceUsageRecord
                    .where(account: Current.account)
                    .for_period(Time.current.beginning_of_month, Time.current.end_of_month)

    last_month = Aloo::VoiceUsageRecord
                 .where(account: Current.account)
                 .for_period(1.month.ago.beginning_of_month, 1.month.ago.end_of_month)

    render json: {
      current_month: {
        transcription_count: current_month.transcriptions.successful.count,
        synthesis_count: current_month.synthesis.successful.count,
        total_cost: current_month.successful.sum(:estimated_cost).to_f.round(4)
      },
      last_month: {
        transcription_count: last_month.transcriptions.successful.count,
        synthesis_count: last_month.synthesis.successful.count,
        total_cost: last_month.successful.sum(:estimated_cost).to_f.round(4)
      },
      quota: build_quota_info
    }
  end

  private

  def build_transcription_stats(usage)
    stats = usage.transcriptions.successful
    {
      count: stats.count,
      total_duration_seconds: stats.sum(:audio_duration_seconds),
      total_duration_minutes: (stats.sum(:audio_duration_seconds) / 60.0).round(2),
      estimated_cost: stats.sum(:estimated_cost).to_f.round(4)
    }
  end

  def build_synthesis_stats(usage)
    stats = usage.synthesis.successful
    {
      count: stats.count,
      total_characters: stats.sum(:characters_used),
      estimated_cost: stats.sum(:estimated_cost).to_f.round(4)
    }
  end

  def build_assistant_breakdown(usage)
    Current.account.aloo_assistants.map do |assistant|
      assistant_usage = usage.where(aloo_assistant_id: assistant.id)
      {
        id: assistant.id,
        name: assistant.name,
        transcription_count: assistant_usage.transcriptions.successful.count,
        synthesis_count: assistant_usage.synthesis.successful.count,
        total_cost: assistant_usage.successful.sum(:estimated_cost).to_f.round(4)
      }
    end
  end

  def build_daily_breakdown(usage)
    usage.successful
         .group('DATE(created_at)')
         .group(:operation_type)
         .select(
           'DATE(created_at) as date',
           'operation_type',
           'COUNT(*) as count',
           'SUM(characters_used) as characters',
           'SUM(audio_duration_seconds) as duration',
           'SUM(estimated_cost) as cost'
         )
         .map do |record|
           {
             date: record.date,
             type: record.operation_type,
             count: record.count,
             characters: record.characters.to_i,
             duration: record.duration.to_i,
             cost: record.cost.to_f.round(4)
           }
         end
  end

  def build_quota_info
    # Check if there's a daily limit configured
    daily_limit = Current.account.custom_attributes&.dig('voice_daily_character_limit') ||
                  ENV.fetch('ALOO_VOICE_DAILY_CHARACTER_LIMIT', 100_000).to_i

    today_usage = Aloo::VoiceUsageRecord
                  .where(account: Current.account)
                  .synthesis
                  .successful
                  .where('created_at > ?', Time.current.beginning_of_day)
                  .sum(:characters_used)

    {
      daily_limit: daily_limit,
      used_today: today_usage,
      remaining: [daily_limit - today_usage, 0].max,
      percentage_used: ((today_usage.to_f / daily_limit) * 100).round(2)
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
