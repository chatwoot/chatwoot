class Api::V1::Accounts::Integrations::RemnawaveController < Api::V1::Accounts::BaseController
  before_action :fetch_hook
  before_action :fetch_remnawave_user, only: [:user_info]
  before_action :fetch_remnawave_user_by_uuid, only: [:enable_user, :disable_user, :reset_traffic]

  def user_info
    return render json: { error: 'no_telegram_id' }, status: :unprocessable_entity if telegram_id.blank?
    return render json: { error: 'user_not_found' }, status: :not_found if @remnawave_user.nil?

    render json: { user: normalize_user(@remnawave_user) }
  end

  def enable_user
    result = api_client.enable_user(params[:uuid])
    return render json: { error: 'action_failed' }, status: :unprocessable_entity if result.nil?

    render json: { user: normalize_user(result.dig('response') || result) }
  end

  def disable_user
    result = api_client.disable_user(params[:uuid])
    return render json: { error: 'action_failed' }, status: :unprocessable_entity if result.nil?

    render json: { user: normalize_user(result.dig('response') || result) }
  end

  def reset_traffic
    result = api_client.reset_traffic(params[:uuid])
    return render json: { error: 'action_failed' }, status: :unprocessable_entity if result.nil?

    render json: { user: normalize_user(result.dig('response') || result) }
  end

  private

  def fetch_hook
    @hook = Integrations::Hook.find_by!(account: Current.account, app_id: 'remnawave')
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'not_configured' }, status: :not_found
  end

  def api_client
    @api_client ||= Integrations::Remnawave::ApiClient.new(
      base_url: @hook.settings['api_url'],
      api_token: @hook.settings['api_token']
    )
  end

  def contact
    @contact ||= Current.account.contacts.find_by(id: params[:contact_id])
  end

  def telegram_id
    @telegram_id ||= contact&.additional_attributes&.dig('social_telegram_user_id')
  end

  def fetch_remnawave_user
    return if telegram_id.blank?

    response = api_client.user_by_telegram_id(telegram_id)
    @remnawave_user = response&.dig('response')&.first || response&.dig('response')
  end

  def fetch_remnawave_user_by_uuid
    uuid = params[:uuid]
    return render json: { error: 'uuid_required' }, status: :unprocessable_entity if uuid.blank?
  end

  def normalize_user(user)
    return {} if user.nil?

    traffic = user['userTraffic'] || {}
    {
      uuid: user['uuid'],
      username: user['username'],
      status: user['status'],
      traffic_limit_bytes: user['trafficLimitBytes'],
      traffic_limit_strategy: user['trafficLimitStrategy'],
      used_traffic_bytes: traffic['usedTrafficBytes'],
      expire_at: user['expireAt'],
      email: user['email'],
      telegram_id: user['telegramId'],
      description: user['description'],
      tag: user['tag'],
      subscription_url: user['subscriptionUrl'],
      created_at: user['createdAt'],
      updated_at: user['updatedAt'],
      sub_last_opened_at: user['subLastOpenedAt'],
      sub_last_user_agent: user['subLastUserAgent']
    }
  end
end
