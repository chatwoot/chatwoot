class Api::V2::Accounts::CustomReportsController < Api::V1::Accounts::BaseController # rubocop:disable Metrics/ClassLength
  include BspdAnalyticsHelper
  include LiveChatAnalyticsHelper

  def index
    builder = V2::CustomReportBuilder.new(Current.account, params)
    result = builder.fetch_data
    render json: result
  end

  def agents_overview
    render json: process_grouped_data(build_report(agents_overview_params))
  end

  def agent_wise_conversation_states
    render json: process_grouped_data(build_report(agent_wise_conversation_states_params))
  end

  def agent_call_overview
    render json: process_grouped_data(build_report(agent_call_overview_params))
  end

  def agent_inbound_call_overview
    render json: process_grouped_data(build_report(agent_inbound_call_overview_params))
  end

  def download_agents_overview
    enqueue_report_generation(download_agents_overview_params)
  end

  def download_agent_wise_conversation_states
    enqueue_report_generation(download_agent_wise_conversation_states_params)
  end

  def download_bot_analytics_overview
    enqueue_report_generation(download_bot_analytics_overview_params)
  end

  def download_bot_analytics_sales_overview
    enqueue_report_generation(download_bot_analytics_sales_overview_params)
  end

  def download_bot_analytics_support_overview
    enqueue_report_generation(download_bot_analytics_support_overview_params)
  end

  def download_live_chat_analytics_overview
    enqueue_report_generation(download_live_chat_analytics_overview_params)
  end

  def download_live_chat_analytics_sales_overview
    enqueue_report_generation(download_live_chat_analytics_sales_overview_params)
  end

  def download_live_chat_analytics_support_overview
    enqueue_report_generation(download_live_chat_analytics_support_overview_params)
  end

  def bot_analytics_overview
    render json: build_report(bot_analytics_overview_params)
  end

  def live_chat_analytics_overview
    render json: build_report(live_chat_analytics_overview_params)
  end

  def bot_analytics_sales_overview
    render json: build_report(bot_analytics_sales_overview_params)
  end

  def live_chat_analytics_sales_overview
    render json: build_report(live_chat_analytics_sales_overview_params)
  end

  def bot_analytics_support_overview
    render json: build_report(bot_analytics_support_overview_params)
  end

  def live_chat_analytics_support_overview
    render json: build_report(live_chat_analytics_support_overview_params)
  end

  def live_chat_other_metrics_overview
    render json: build_report(live_chat_other_metrics_overview_params)
  end

  def label_wise_conversation_states
    report_data = build_report(label_wise_conversation_states_params)

    # Extract the metrics data from the response
    conversation_data = report_data[:data]['conversation_with_label'] || {}
    percentage_data = report_data[:data]['label_percentage'] || {}

    # Transform the data into the desired format
    result = []

    # Combine both metrics into a single object for each label
    all_labels = (conversation_data.keys + percentage_data.keys).uniq

    Rails.logger.info("all_labelsData, #{conversation_data.inspect}")

    all_labels.each do |label|
      result << {
        id: label,
        conversation_with_label: conversation_data[label],
        label_percentage: percentage_data[label]
      }
    end

    render json: result
  end

  def shop_currency
    render json: { currency: bspd_shop_currency(Current.account.id) }
  end

  def live_chat_shop_currency
    render json: { currency: get_live_chat_shop_currency(Current.account.id) }
  end

  def bot_flows
    shop_url = fetch_shop_url(Current.account.id)

    if shop_url.blank?
      render json: { success: false, flows: [], error: 'Shop URL not found' }
      return
    end

    flows = fetch_flows_from_api(shop_url)
    render json: flows
  rescue StandardError => e
    Rails.logger.error("Error fetching bot flows: #{e.message}")
    render json: { success: false, flows: [], error: e.message }, status: :internal_server_error
  end

  private

  def build_report(input)
    V2::CustomReportBuilder.new(Current.account, input).fetch_data
  end

  def process_grouped_data(result)
    result[:data][:grouped_data].filter_map do |group, data|
      data.merge(id: group) unless data.is_a?(String)
    end
  end

  def enqueue_report_generation(input)
    CustomReportJob.perform_later(Current.account, input, params[:email])
    render json: { message: 'Report generation started', email: params[:email], input: input }
  end

  def base_filters
    {
      time_period: {
        type: 'custom',
        start_date: params[:since],
        end_date: params[:until]
      },
      business_hours: params[:business_hours],
      inboxes: params[:inboxes],
      agents: params[:agents],
      labels: params[:labels]
    }
  end

  def bot_base_filters
    api_inbox_ids = Current.account.inboxes.where(channel_type: 'Channel::Api').pluck(:id)
    filters = {
      time_period: {
        type: 'custom',
        start_date: params[:since],
        end_date: params[:until]
      },
      business_hours: params[:business_hours],
      inboxes: api_inbox_ids,
      agents: params[:agents],
      labels: params[:labels]
    }

    filters[:flow_id] = params[:flow_id] if params[:flow_id].present?

    filters
  end

  def live_chat_base_filters
    web_widget_inbox_ids = Current.account.inboxes.where(channel_type: 'Channel::WebWidget').pluck(:id)
    {
      time_period: {
        type: 'custom',
        start_date: params[:since],
        end_date: params[:until]
      },
      business_hours: params[:business_hours],
      inboxes: web_widget_inbox_ids,
      agents: params[:agents],
      labels: params[:labels]
    }
  end

  # rubocop:disable Layout/LineLength
  def agents_overview_params
    {
      metrics: %w[resolved avg_first_response_time avg_resolution_time avg_response_time avg_resolution_time_of_new_assigned_conversations
                  avg_resolution_time_of_carry_forwarded_conversations avg_resolution_time_of_reopened_conversations median_first_response_time median_resolution_time median_resolution_time_of_new_assigned_conversations median_resolution_time_of_carry_forwarded_conversations median_resolution_time_of_reopened_conversations median_response_time median_csat_score total_online_time],
      group_by: 'agent',
      filters: base_filters
    }
  end
  # rubocop:enable Layout/LineLength

  def bot_analytics_overview_params
    {
      metrics: %w[bot_total_revenue sales_ooo_hours bot_resolved],
      filters: bot_base_filters
    }
  end

  def bot_analytics_sales_overview_params
    {
      metrics: %w[pre_sale_queries bot_orders_placed bot_revenue_generated],
      group_by: 'working_hours',
      filters: bot_base_filters
    }
  end

  def bot_analytics_support_overview_params
    {
      metrics: %w[bot_handled bot_resolved bot_avg_resolution_time bot_assign_to_agent],
      group_by: 'working_hours',
      filters: bot_base_filters
    }
  end

  # live chat analytics functions
  def live_chat_analytics_overview_params
    {
      metrics: %w[live_chat_total_revenue live_chat_sales_ooo_hours bot_resolved],
      filters: live_chat_base_filters
    }
  end

  def live_chat_analytics_sales_overview_params
    {
      metrics: %w[pre_sale_queries live_chat_orders_placed live_chat_revenue_generated],
      group_by: 'working_hours',
      filters: live_chat_base_filters
    }
  end

  def live_chat_analytics_support_overview_params
    {
      metrics: %w[bot_handled bot_resolved bot_avg_resolution_time bot_assign_to_agent],
      group_by: 'working_hours',
      filters: live_chat_base_filters
    }
  end

  def live_chat_other_metrics_overview_params
    {
      metrics: %w[live_chat_impressions live_chat_widget_opened live_chat_intent_match live_chat_fall_back live_chat_csat_metrics
                  total_conversations],
      filters: live_chat_base_filters
    }
  end

  def agent_wise_conversation_states_params
    {
      metrics: %w[handled new_assigned open reopened carry_forwarded waiting_customer_response waiting_agent_response resolved
                  resolved_in_pre_time_range resolved_in_time_range snoozed],
      group_by: 'agent',
      filters: base_filters
    }
  end

  def label_wise_conversation_states_params
    {
      metrics: %w[conversation_with_label label_percentage],
      group_by: 'labels',
      filters: base_filters
    }
  end

  # rubocop:disable Layout/LineLength
  def agent_call_overview_params # rubocop:disable Metrics/MethodLength
    account_id = Current.account.id
    case account_id
    when 1058, 1126, 1125
      {
        metrics: %w[total_calling_nudged_conversations scheduled_call_conversations ringing_no_response_conversations hung_up_after_intro_conversations conversation_happened_conversations
                    asked_to_whatsapp_conversations already_purchased_conversations dont_want_conversations asked_to_call_later other_conversations agent_revenue_generated avg_time_to_call_after_nudge avg_time_to_convert avg_time_to_drop avg_follow_up_calls],
        group_by: 'agent',
        filters: base_filters
      }
    when 1179
      {
        metrics: %w[total_calling_nudged_conversations scheduled_call_conversations switched_off_conversations
                    busy_tone_conversations
                    pending_conversations
                    query_resolved_conversations
                    successfully_done_conversations
                    call_back_conversations
                    snooze_conversations agent_revenue_generated avg_time_to_call_after_nudge avg_time_to_convert avg_time_to_drop avg_follow_up_calls],
        group_by: 'agent',
        filters: base_filters
      }
    else
      {
        metrics: %w[total_calling_nudged_conversations scheduled_call_conversations not_picked_up_call_conversations follow_up_call_conversations
                    converted_call_conversations dropped_call_conversations agent_revenue_generated avg_time_to_call_after_nudge avg_time_to_convert avg_time_to_drop avg_follow_up_calls],
        group_by: 'agent',
        filters: base_filters
      }
    end
  end

  def agent_inbound_call_overview_params
    {
      metrics: %w[total_inbound_calls_handled total_calls_missed inbound_calls_resolved total_inbound_call_conversations avg_call_handling_time avg_call_wait_time],
      group_by: 'agent',
      filters: base_filters
    }
  end

  # rubocop:enable Layout/LineLength
  def download_agents_overview_params
    {
      metrics: ['resolved'] + send(:"#{params[:metric_type]&.downcase}_metrics"),
      group_by: 'agent',
      filters: base_filters
    }
  end

  def download_agent_wise_conversation_states_params
    agent_wise_conversation_states_params
  end

  def download_bot_analytics_overview_params
    bot_analytics_overview_params
  end

  def download_bot_analytics_sales_overview_params
    bot_analytics_sales_overview_params
  end

  def download_bot_analytics_support_overview_params
    bot_analytics_support_overview_params
  end

  def download_live_chat_analytics_overview_params
    live_chat_analytics_overview_params
  end

  def download_live_chat_analytics_sales_overview_params
    live_chat_analytics_sales_overview_params
  end

  def download_live_chat_analytics_support_overview_params
    live_chat_analytics_support_overview_params
  end

  def average_metrics
    %w[avg_first_response_time avg_resolution_time avg_resolution_time_of_time_range avg_resolution_time_of_pre_time_range avg_response_time
       avg_csat_score]
  end

  def median_metrics
    %w[median_first_response_time median_resolution_time median_response_time median_csat_score]
  end

  def fetch_flows_from_api(shop_url)
    response = HTTParty.get(
      'https://mcfsmik3g0.execute-api.us-east-1.amazonaws.com/flows/metadata',
      query: { shopUrl: shop_url, channel: 'WHATSAPP' }
    )

    return { success: false, flows: [] } unless response.success?

    JSON.parse(response.body)
  rescue StandardError => e
    Rails.logger.error("Error calling flows metadata API: #{e.message}")
    { success: false, flows: [], error: e.message }
  end
end
