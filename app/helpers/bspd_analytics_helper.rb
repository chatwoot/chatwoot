module BspdAnalyticsHelper
  include WorkingHoursHelper

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

  private

  def fetch_bot_attributions(account_id, use_time_qualifier: false, time_range: nil)
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
        from: time_range.begin.strftime('%Y-%m-%d'),
        to: time_range.end.strftime('%Y-%m-%d')
      }.to_json
    end

    response = HTTParty.get('https://43r09s4nl9.execute-api.us-east-1.amazonaws.com/chatwoot/botAttributions', query: params)
    JSON.parse(response.body)
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
