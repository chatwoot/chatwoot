class Api::V1::Accounts::Autonomia::Prospecting::SettingsController < Api::V1::Accounts::Autonomia::Prospecting::BaseController
  def show
    render json: { payload: setting_payload(setting) }
  end

  def update
    current_setting = setting
    current_setting.assign_attributes(settings_attributes)
    current_setting.google_places_api_key = nil if clear_google_places_api_key?
    current_setting.save!

    render json: { payload: setting_payload(current_setting) }
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
  end

  private

  def settings_params
    params.require(:settings).permit(
      :provider,
      :provider_enabled,
      :default_limit,
      :max_results_per_search,
      :daily_limit,
      :monthly_limit,
      :cache_ttl_seconds,
      :default_crm_pipeline_id,
      :default_crm_stage_id,
      :google_places_api_key,
      :clear_google_places_api_key
    )
  end

  def settings_attributes
    settings_params.to_h.symbolize_keys.except(:clear_google_places_api_key).tap do |attributes|
      attributes.delete(:google_places_api_key) if attributes[:google_places_api_key].blank?
    end
  end

  def clear_google_places_api_key?
    ActiveModel::Type::Boolean.new.cast(settings_params.to_h['clear_google_places_api_key'])
  end

  def setting_payload(current_setting)
    current_setting.as_json(
      only: [
        :id, :provider, :provider_enabled, :default_limit, :max_results_per_search,
        :daily_limit, :monthly_limit, :cache_ttl_seconds, :enrichment_enabled,
        :default_crm_pipeline_id, :default_crm_stage_id, :created_at, :updated_at
      ]
    ).merge(
      has_google_places_api_key: current_setting.google_places_configured?,
      usage: usage_payload(current_setting)
    )
  end

  def usage_payload(current_setting)
    daily_used = usage_since(Time.current.beginning_of_day)
    monthly_used = usage_since(Time.current.beginning_of_month)

    {
      daily_used: daily_used,
      monthly_used: monthly_used,
      daily_remaining: remaining_usage(current_setting.daily_limit, daily_used),
      monthly_remaining: remaining_usage(current_setting.monthly_limit, monthly_used)
    }
  end

  def usage_since(period_start)
    searches_scope.where('created_at >= ?', period_start).sum(:consumed_api_units)
  end

  def remaining_usage(limit, used)
    return nil if limit.blank?

    [limit.to_i - used.to_i, 0].max
  end
end
