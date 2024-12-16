class Api::V2::Accounts::CustomReportsController < Api::V1::Accounts::BaseController
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

  def bot_analytics_overview
    render json: build_report(bot_analytics_overview_params)
  end

  def bot_analytics_sales_overview
    render json: build_report(bot_analytics_sales_overview_params)
  end

  def bot_analytics_support_overview
    render json: build_report(bot_analytics_support_overview_params)
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
    {
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
  end

  # rubocop:disable Layout/LineLength
  def agents_overview_params
    {
      metrics: %w[resolved avg_first_response_time avg_resolution_time avg_response_time avg_resolution_time_of_new_assigned_conversations
                  avg_resolution_time_of_carry_forwarded_conversations avg_resolution_time_of_reopened_conversations median_first_response_time median_resolution_time median_resolution_time_of_new_assigned_conversations median_resolution_time_of_carry_forwarded_conversations median_resolution_time_of_reopened_conversations median_response_time median_csat_score],
      group_by: 'agent',
      filters: base_filters
    }
  end
  # rubocop:enable Layout/LineLength

  def bot_analytics_overview_params
    {
      metrics: %w[bot_total_revenue sales_ooo_hours bot_handled],
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

  def agent_wise_conversation_states_params
    {
      metrics: %w[handled new_assigned open reopened carry_forwarded waiting_customer_response waiting_agent_response resolved snoozed],
      group_by: 'agent',
      filters: base_filters
    }
  end

  # rubocop:disable Layout/LineLength
  def agent_call_overview_params
    {
      metrics: %w[total_calling_nudged_conversations scheduled_call_conversations not_picked_up_call_conversations follow_up_call_conversations
                  converted_call_conversations dropped_call_conversations avg_time_to_call_after_nudge avg_time_to_convert avg_time_to_drop avg_follow_up_calls],
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

  def average_metrics
    %w[avg_first_response_time avg_resolution_time avg_response_time avg_csat_score]
  end

  def median_metrics
    %w[median_first_response_time median_resolution_time median_response_time median_csat_score]
  end
end
