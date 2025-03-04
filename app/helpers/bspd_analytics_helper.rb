# rubocop:disable Metrics/ModuleLength
# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/PerceivedComplexity
module BspdAnalyticsHelper
  include WorkingHoursHelper

  BOT_ATTRIBUTIONS_TTL = 1.minute
  CURRENCY_TTL = 24.hours

  def bot_total_revenue(account_id, time_range)
    bot_attributions = fetch_bot_attributions(account_id, use_time_qualifier: false, time_range: time_range)

    bot_attributions['chatbot_working_hours']['revenue'] + bot_attributions['chatbot_ooo_hours']['revenue']
  end

  def sales_ooo_hours(account_id, time_range)
    bot_attributions = fetch_bot_attributions(account_id, use_time_qualifier: false, time_range: time_range)

    bot_attributions['chatbot_ooo_hours']['count']
  end

  def bot_orders_placed(account_id, time_range)
    bot_attributions = fetch_bot_attributions(account_id, use_time_qualifier: false, time_range: time_range)

    Rails.logger.info "Time Range: #{time_range.inspect}"
    Rails.logger.info "bot_attributions: #{bot_attributions}"

    {
      working_hours: bot_attributions['chatbot_working_hours']['count'],
      non_working_hours: bot_attributions['chatbot_ooo_hours']['count']
    }
  end

  def bot_revenue_generated(account_id, time_range)
    bot_attributions = fetch_bot_attributions(account_id, use_time_qualifier: false, time_range: time_range)

    Rails.logger.info "bot_attributions: #{bot_attributions}"

    {
      working_hours: bot_attributions['chatbot_working_hours']['revenue'],
      non_working_hours: bot_attributions['chatbot_ooo_hours']['revenue']
    }
  end

  def agent_revenue_generated(account_id, time_range)
    agent_attributions = fetch_agent_attributions(account_id, use_time_qualifier: false, time_range: time_range)

    Rails.logger.info "agent_attributions: #{agent_attributions}"

    revenue_by_agent = {}
    agent_attributions.each do |agent_id, data|
      next if agent_id == 'currency'

      revenue_by_agent[agent_id.to_i] = data['revenue'] || 0
    end

    Rails.logger.info "revenue_by_agent: #{revenue_by_agent}"

    revenue_by_agent
  end

  def bspd_shop_currency(account_id)
    cache_key = "shop_currency:#{account_id}"
    cached_currency = Redis::Alfred.get(cache_key)
    return cached_currency if cached_currency.present?

    bot_attributions = fetch_bot_attributions(account_id, use_time_qualifier: false, time_range: nil)

    currency = bot_attributions['currency']
    Redis::Alfred.setex(cache_key, currency, CURRENCY_TTL) if currency.present?

    currency
  end

  private

  def fetch_bot_attributions(account_id, use_time_qualifier: false, time_range: nil)
    cache_key = "bot_attributions:#{account_id}:#{time_range&.begin}:#{time_range&.end}"
    cached_data = Redis::Alfred.get(cache_key)
    return JSON.parse(cached_data) if cached_data.present?

    response_data = fetch_bot_attributions_from_api(account_id, use_time_qualifier, time_range)
    Redis::Alfred.setex(cache_key, response_data.to_json, BOT_ATTRIBUTIONS_TTL) if response_data.present?
    response_data
  end

  def fetch_agent_attributions(account_id, use_time_qualifier: false, time_range: nil)
    cache_key = "agent_attributions:#{account_id}:#{time_range&.begin}:#{time_range&.end}"
    cached_data = Redis::Alfred.get(cache_key)
    return JSON.parse(cached_data) if cached_data.present?

    response_data = fetch_agent_attributions_from_api(account_id, use_time_qualifier, time_range)
    Redis::Alfred.setex(cache_key, response_data.to_json, BOT_ATTRIBUTIONS_TTL) if response_data.present?
    response_data
  end

  # rubocop:disable Metrics/MethodLength
  def fetch_agent_attributions_from_api(account_id, use_time_qualifier, time_range)
    shop_url = fetch_shop_url(account_id)
    agents = Account.find(account_id).users
    agent_ids = agents.map(&:id)
    time_offset = 330

    params = {
      shopUrl: shop_url,
      timeOffset: time_offset,
      agentIds: "[#{agent_ids.join(',')}]"
    }

    if use_time_qualifier
      params[:timeQualifier] = 'Last 7 Days'
    else
      params[:timeQualifier] = 'Custom'
      params[:timeQuantifier] = {
        from: time_range&.begin&.strftime('%Y-%m-%d'),
        to: time_range&.end&.strftime('%Y-%m-%d')
      }.to_json
    end

    Rails.logger.info "agent_attributions_params: #{params}"

    response = HTTParty.get('https://43r09s4nl9.execute-api.us-east-1.amazonaws.com/chatwoot/agentAttributions', query: params)
    JSON.parse(response.body)
  rescue StandardError => e
    Rails.logger.error("Error fetching agent attributions: #{e.message}")
    default_response = { 'currency' => nil }
    agents.each do |agent|
      default_response[agent.id.to_s] = { 'count' => 0, 'revenue' => 0 }
    end
    default_response
  end

  def fetch_bot_attributions_from_api(account_id, use_time_qualifier, time_range)
    shop_url = fetch_shop_url(account_id)
    time_offset = 330

    params = {
      shopUrl: shop_url,
      timeOffset: time_offset
    }

    if use_time_qualifier
      params[:timeQualifier] = 'Last 7 Days'
    else
      params[:timeQualifier] = 'Custom'
      params[:timeQuantifier] = {
        from: time_range&.begin&.strftime('%Y-%m-%d'),
        to: time_range&.end&.strftime('%Y-%m-%d')
      }.to_json
    end

    response = HTTParty.get('https://43r09s4nl9.execute-api.us-east-1.amazonaws.com/chatwoot/botAttributions', query: params)
    JSON.parse(response.body)
  rescue StandardError => e
    Rails.logger.error("Error fetching bot attributions: #{e.message}")
    {
      'chatbot_working_hours' => { 'count' => 0, 'revenue' => 0 },
      'chatbot_ooo_hours' => { 'count' => 0, 'revenue' => 0 },
      'currency' => nil
    }
  end
  # rubocop:enable Metrics/MethodLength
end

# fetch_bot_attributions response format: :{
#   "chatbot_working_hours": {
#     "count": 100,
#     "revenue": 8000,
#   },
#   "chatbot_ooo_hours": {
#     "count": 10,
#     "revenue": 1000
#   }
# }
# TODO:
# replace proxy with container link
# Test out email reports
# Fix handled timeout issue
# Also cache the bot attribution in redis, with ttl of 1 hour and add a default value as 0 if api request fails
# Add loading indicators for both views(chatbot and agent)
# Also fix the icons for chatbot.

# rubocop:enable Metrics/ModuleLength
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/CyclomaticComplexity
# rubocop:enable Metrics/PerceivedComplexity
