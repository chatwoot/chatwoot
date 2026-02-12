class Api::V1::Accounts::Integrations::CalendlyController < Api::V1::Accounts::BaseController
  before_action :check_admin_authorization?
  before_action :fetch_hook

  def event_types
    event_types = api_client.list_event_types
    render json: event_types, status: :ok
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def create_scheduling_link
    event_type_uri = params[:event_type_uri] || @hook.settings['default_event_type_uri']
    render json: { error: 'No event type specified' }, status: :unprocessable_entity and return if event_type_uri.blank?

    link = api_client.create_scheduling_link(event_type_uri, max_event_count: params[:max_event_count]&.to_i || 1)
    render json: link, status: :ok
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def scheduled_events
    events = api_client.list_scheduled_events(
      min_start_time: params[:min_start_time] ? Time.zone.parse(params[:min_start_time]) : nil,
      max_start_time: params[:max_start_time] ? Time.zone.parse(params[:max_start_time]) : nil,
      status: params[:status] || 'active'
    )
    render json: events, status: :ok
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def cancel_event
    event_uuid = params[:event_uuid]
    render json: { error: 'No event UUID specified' }, status: :unprocessable_entity and return if event_uuid.blank?

    api_client.cancel_event(event_uuid, reason: params[:reason])
    render json: { success: true }, status: :ok
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def available_times
    event_type_uri = resolve_event_type_uri
    render json: { error: 'No event type specified' }, status: :unprocessable_entity and return if event_type_uri.blank?

    times = api_client.list_available_times(event_type_uri, start_time: resolve_start_time, end_time: resolve_end_time)
    render json: times, status: :ok
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def update_settings
    permitted = params.permit(:default_event_type_uri, :default_event_type_name)
    @hook.settings.merge!(permitted.to_h)
    @hook.save!
    render json: @hook.settings, status: :ok
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def destroy
    delete_webhook_subscription
    @hook.destroy!
    head :ok
  rescue StandardError => e
    Rails.logger.error("Calendly disconnect error: #{e.message}")
    # Still destroy the hook even if webhook deletion fails
    @hook.destroy!
    head :ok
  end

  private

  def resolve_event_type_uri
    params[:event_type_uri] || @hook.settings['default_event_type_uri']
  end

  def resolve_start_time
    params[:start_time] ? Time.zone.parse(params[:start_time]) : Time.current
  end

  def resolve_end_time
    params[:end_time] ? Time.zone.parse(params[:end_time]) : 7.days.from_now
  end

  def delete_webhook_subscription
    webhook_uri = @hook.settings['webhook_subscription_uri']
    return if webhook_uri.blank?

    uuid = webhook_uri.split('/').last
    api_client.delete_webhook_subscription(uuid)
  rescue StandardError => e
    Rails.logger.error("Failed to delete Calendly webhook subscription: #{e.message}")
  end

  def api_client
    @api_client ||= Integrations::Calendly::ApiClient.new(@hook)
  end

  def fetch_hook
    @hook = Current.account.hooks.find_by!(app_id: 'calendly')
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Calendly integration not connected' }, status: :not_found
  end
end
