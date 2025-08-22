# rubocop:disable Metrics/ModuleLength
module LiveChatAnalyticsHelper
  include WorkingHoursHelper

  BOT_ATTRIBUTIONS_TTL = 1.minute
  CURRENCY_TTL = 24.hours

  def live_chat_total_revenue(account_id, time_range)
    bot_attributions = fetch_live_chat_attributions(account_id, use_time_qualifier: false, time_range: time_range)

    Rails.logger.info("bot_attributions, #{bot_attributions}")

    bot_attributions['attribution']['live_chat_working_hours']['revenue'] + bot_attributions['attribution']['live_chat_ooo_hours']['revenue']
  end

  def live_chat_sales_ooo_hours(account_id, time_range)
    bot_attributions = fetch_live_chat_attributions(account_id, use_time_qualifier: false, time_range: time_range)

    bot_attributions['attribution']['live_chat_ooo_hours']['count']
  end

  def live_chat_orders_placed(account_id, time_range)
    bot_attributions = fetch_live_chat_attributions(account_id, use_time_qualifier: false, time_range: time_range)

    Rails.logger.info "Time Range: #{time_range.inspect}"
    Rails.logger.info "bot_attributions: #{bot_attributions}"

    {
      working_hours: bot_attributions['attribution']['live_chat_working_hours']['count'],
      non_working_hours: bot_attributions['attribution']['live_chat_ooo_hours']['count']
    }
  end

  def live_chat_revenue_generated(account_id, time_range)
    bot_attributions = fetch_live_chat_attributions(account_id, use_time_qualifier: false, time_range: time_range)

    Rails.logger.info "bot_attributions: #{bot_attributions}"

    {
      working_hours: bot_attributions['attribution']['live_chat_working_hours']['revenue'],
      non_working_hours: bot_attributions['attribution']['live_chat_ooo_hours']['revenue']
    }
  end

  def live_chat_impressions(account_id, time_range)
    cache_key = "live_chat_impressions:#{account_id}:#{time_range&.begin}:#{time_range&.end}"
    cached_data = Redis::Alfred.get(cache_key)
    return cached_data.to_i if cached_data.present?

    begin
      # Use timeout to prevent hanging
      Timeout.timeout(8) do
        bot_attributions = fetch_live_chat_other_metrics(account_id, use_time_qualifier: false, time_range: time_range)
        result = bot_attributions['impressions'] || 0
        Redis::Alfred.setex(cache_key, result.to_s, 5.minutes)
        result
      end
    rescue StandardError => e
      Rails.logger.error("live_chat_impressions timeout/error: #{e.message}")
      0
    end
  end

  def live_chat_widget_opened(account_id, time_range)
    bot_attributions = fetch_live_chat_other_metrics(account_id, use_time_qualifier: false, time_range: time_range)

    bot_attributions['webWidgetOpened']
  end

  def live_chat_intent_match(account_id, time_range) # rubocop:disable Metrics/MethodLength
    cache_key = "live_chat_intent_match_combined:#{account_id}:#{time_range&.begin}:#{time_range&.end}"
    cached_data = Redis::Alfred.get(cache_key)
    return JSON.parse(cached_data) if cached_data.present?

    default_response = {
      'aiIntentMatchPercentage' => 0,
      'intentMatching' => {
        'product_query' => 0,
        'track_order' => 0,
        'general_message' => 0,
        'unrelated_query' => 0,
        'agent_assignment' => 0,
        'product_link_query' => 0,
        'product_disadvantage' => 0,
        'product_search' => 0,
        'discount_query' => 0,
        'intent_match' => 0
      }
    }

    begin
      # Use concurrent calls with timeout
      Timeout.timeout(8) do
        bot_attributions_future = Concurrent::Future.execute do
          fetch_live_chat_conversation_metrics(account_id, use_time_qualifier: false, time_range: time_range)
        end

        final_data_future = Concurrent::Future.execute do
          fetch_live_chat_intent_match_break_down_metrics(account_id, use_time_qualifier: false, time_range: time_range)
        end

        bot_attributions = bot_attributions_future.value(6)
        final_data = final_data_future.value(6)

        result = {
          'aiIntentMatchPercentage' => bot_attributions['aiIntentMatchPercentage'] || 0,
          'intentMatching' => final_data['intentMatching'] || default_response['intentMatching']
        }

        Redis::Alfred.setex(cache_key, result.to_json, 5.minutes)
        result
      end
    rescue StandardError => e
      Rails.logger.error("live_chat_intent_match timeout/error: #{e.message}")
      default_response
    end
  end

  def live_chat_fall_back(account_id, time_range)
    cache_key = "live_chat_fall_back:#{account_id}:#{time_range&.begin}:#{time_range&.end}"
    cached_data = Redis::Alfred.get(cache_key)
    return cached_data.to_f if cached_data.present?

    begin
      # Use timeout to prevent hanging
      Timeout.timeout(8) do
        bot_attributions = fetch_live_chat_conversation_metrics(account_id, use_time_qualifier: false, time_range: time_range)
        result = bot_attributions['fallbackPercentage'] || 0
        Redis::Alfred.setex(cache_key, result.to_s, 5.minutes)
        result
      end
    rescue StandardError => e
      Rails.logger.error("live_chat_fall_back timeout/error: #{e.message}")
      0
    end
  end

  def get_live_chat_shop_currency(account_id)
    cache_key = "live_chat_shop_currency:#{account_id}"
    cached_currency = Redis::Alfred.get(cache_key)
    return cached_currency if cached_currency.present?

    bot_attributions = fetch_live_chat_attributions(account_id, use_time_qualifier: false, time_range: nil)

    currency = bot_attributions['currency']
    Redis::Alfred.setex(cache_key, currency, CURRENCY_TTL) if currency.present?

    currency
  end

  private

  def fetch_live_chat_attributions(account_id, use_time_qualifier: false, time_range: nil)
    cache_key = "live_chat_attributions:#{account_id}:#{time_range&.begin}:#{time_range&.end}"
    cached_data = Redis::Alfred.get(cache_key)
    return JSON.parse(cached_data) if cached_data.present?

    response_data = fetch_live_chat_attributions_from_api(account_id, use_time_qualifier, time_range)
    Redis::Alfred.setex(cache_key, response_data.to_json, BOT_ATTRIBUTIONS_TTL) if response_data.present?
    response_data
  end

  def fetch_live_chat_other_metrics(account_id, use_time_qualifier: false, time_range: nil)
    cache_key = "live_chat_other_metrics:#{account_id}:#{time_range&.begin}:#{time_range&.end}"
    cached_data = Redis::Alfred.get(cache_key)
    return JSON.parse(cached_data) if cached_data.present?

    response_data = fetch_live_chat_other_metrics_from_api(account_id, use_time_qualifier, time_range)

    Rails.logger.info("response_dataOtherMetrics, #{response_data}")
    Redis::Alfred.setex(cache_key, response_data.to_json, BOT_ATTRIBUTIONS_TTL) if response_data.present?
    response_data
  end

  def fetch_live_chat_conversation_metrics(account_id, use_time_qualifier: false, time_range: nil)
    cache_key = "live_chat_conversation_metrics:#{account_id}:#{time_range&.begin}:#{time_range&.end}"
    cached_data = Redis::Alfred.get(cache_key)
    return JSON.parse(cached_data) if cached_data.present?

    response_data = fetch_live_chat_conversation_metrics_from_api(account_id, use_time_qualifier, time_range)

    Rails.logger.info("fetch_live_chat_conversation_metrics, #{response_data}")

    Redis::Alfred.setex(cache_key, response_data.to_json, BOT_ATTRIBUTIONS_TTL) if response_data.present?
    response_data
  end

  def fetch_live_chat_intent_match_break_down_metrics(account_id, use_time_qualifier: false, time_range: nil)
    cache_key = "live_chat_intent_match_break_down_metrics:#{account_id}:#{time_range&.begin}:#{time_range&.end}"
    cached_data = Redis::Alfred.get(cache_key)
    return JSON.parse(cached_data) if cached_data.present?

    response_data = fetch_live_chat_intent_match_break_down_metrics_from_api(account_id, use_time_qualifier, time_range)

    Rails.logger.info("fetch_live_chat_conversation_metrics, #{response_data}")
    Redis::Alfred.setex(cache_key, response_data.to_json, BOT_ATTRIBUTIONS_TTL) if response_data.present?
    response_data
  end

  def fetch_live_chat_attributions_from_api(account_id, use_time_qualifier, time_range) # rubocop:disable Metrics/MethodLength
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

    response = HTTParty.get('https://43r09s4nl9.execute-api.us-east-1.amazonaws.com/chatwoot/liveChatBotAttributions', query: params)
    JSON.parse(response.body)
  rescue StandardError => e
    Rails.logger.error("Error fetching live chat attributions: #{e.message}")
    {
      'attribution' => {
        'live_chat_ooo_hours' => { 'count' => 0, 'revenue' => 0 },
        'live_chat_working_hours' => { 'count' => 0, 'revenue' => 0 }
      },
      'currency' => nil
    }
  end

  def fetch_live_chat_other_metrics_from_api(account_id, use_time_qualifier, time_range) # rubocop:disable Metrics/MethodLength
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
      params[:timeQuantifierFrom] = time_range&.begin&.strftime('%Y-%m-%d')
      params[:timeQuantifierTo] = time_range&.end&.strftime('%Y-%m-%d')
    end

    response = HTTParty.get('https://43r09s4nl9.execute-api.us-east-1.amazonaws.com/chatbot/livechatImpressionAnalytics', query: params)
    JSON.parse(response.body)
  rescue StandardError => e
    Rails.logger.error("Error fetching impressions metrics: #{e.message}")
    {
      'impressions' => 0,
      'webWidgetOpened' => 0
    }
  end

  def fetch_live_chat_conversation_metrics_from_api(account_id, use_time_qualifier, time_range) # rubocop:disable Metrics/MethodLength
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
      params[:timeQuantifierFrom] = time_range&.begin&.strftime('%Y-%m-%d')
      params[:timeQuantifierTo] = time_range&.end&.strftime('%Y-%m-%d')
    end

    response = HTTParty.get('https://43r09s4nl9.execute-api.us-east-1.amazonaws.com/chatbot/livechatConversationData', query: params)
    JSON.parse(response.body)
  rescue StandardError => e
    Rails.logger.error("Error fetching Live Chat conversation Metrics: #{e.message}")
    {
      'aiIntentMatchPercentage' => 0,
      'fallbackPercentage' => 0
    }
  end

  def fetch_live_chat_intent_match_break_down_metrics_from_api(account_id, use_time_qualifier, time_range) # rubocop:disable Metrics/MethodLength
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
      params[:timeQuantifierFrom] = time_range&.begin&.strftime('%Y-%m-%d')
      params[:timeQuantifierTo] = time_range&.end&.strftime('%Y-%m-%d')
    end

    response = HTTParty.get('https://rest-apis-767152501284.us-east4.run.app/api/v1/chatbot/wa/getIntentMatching', query: params)

    JSON.parse(response.body)
  rescue StandardError => e
    Rails.logger.error("Error fetching Live Chat conversation Metrics: #{e.message}")
    {
      'success': true,
      'intentMatching': {
        'product_query': 0,
        'track_order': 0,
        'general_message': 0,
        'unrelated_query': 0,
        'agent_assignment': 0,
        'product_link_query': 0,
        'product_disadvantage': 0,
        'product_search': 0,
        'discount_query': 0,
        'intent_match': 0
      }
    }
  end
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
