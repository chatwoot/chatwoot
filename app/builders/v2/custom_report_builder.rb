class V2::CustomReportBuilder # rubocop:disable Metrics/ClassLength
  include DateRangeHelper
  include CustomReportHelper
  include BspdAnalyticsHelper
  include LiveChatAnalyticsHelper

  attr_reader :account, :params

  DEFAULT_GROUP_BY = 'day'.freeze
  AGENT_RESULTS_PER_PAGE = 25

  def initialize(account, params)
    @account = account
    @config = params

    @metrics = params[:metrics]
    @filters = params[:filters]
    @group_by = params[:group_by]
    @flow_id = params[:filters][:flow_id] if params[:filters]
    @metric_timings = {}

    timezone_offset = (params[:timezone_offset] || 0).to_f
    @timezone = ActiveSupport::TimeZone[timezone_offset]&.name

    Rails.logger.info "CustomReportBuilder: timezone_offset - #{params}"

    @time_range = process_custom_time_range(@filters[:time_period])
  end

  # type TimeRange = {
  #   type: 'dynamic';
  #   value: number;
  #   unit: 'day' | 'week' | 'month' | 'year';
  # } | {
  #   type: 'custom'; // for custom dates
  #   start_date: string; // Unix Timestamp format
  #   end_date: string;   // Unix Timestamp format
  # };

  # type MetricKey = 'handled' | 'new_assigned' | 'open' | 'reopened' |
  #                 'carry_forwarded' | 'resolved' | 'waiting_agent_response' |
  #                 'waiting_customer_response' | 'snoozed' | 'avg_first_response_time' |
  #                 'avg_resolution_time' | 'avg_response_time' | 'avg_csat_score'
  #                 'median_first_response_time' | 'median_resolution_time' | 'median_response_time' |
  #                 'median_csat_score';

  # type GroupBy = 'agent' | 'inbox' | 'label';

  # interface config {
  #   metrics: MetricKey[];
  #   filters: {
  #     time_period: TimeRange;
  #     business_hours?: boolean;
  #     inboxes?: number[];
  #     agents?: number[];
  #     labels?: string[];
  #   };
  #   group_by?: GroupBy;
  # }

  # Response
  # {
  #   "time_range": {
  #     "start": string, // Unix Timestamp
  #     "end": string    // Unix Timestamp
  #   },
  #   "data": {
  #     [metric: MetricKey]?: number,
  #     "grouped_data"?: {
  # 		    grouped_by: string,
  #         [groupKey: string]: {
  #           [metric: MetricKey]: number,
  #         }
  #       }
  #   }
  # }

  # Metrics
  # - Conversation States
  #     - Handled
  #     - New Assigned
  #     - Open
  #     - Reopened
  #     - Carry Forwarded
  #     - Resolved
  #     - Waiting Agent Response
  #     - Waiting Customer Response
  #     - Snoozed
  # - Agent Metrics
  #     - (Avg) First Response Time
  #     - (Avg) Resolution Time
  #     - (Avg) Response Time
  #     - (Avg) CSAT Score

  ## Filters:
  # - Time Period
  # - Business Hours - toggle
  # - Inboxes
  # - Agents
  # - Labels

  ## Group By:
  # - Agents
  # - Inboxes
  # - Labels

  # !!!TODO: implement for label groupby

  # TODO: figure out if agent filter needs to be applied with ConversationAssignment

  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/PerceivedComplexity
  def fetch_data
    data = {}
    data[:grouped_data] = {}

    begin
      @metrics.each do |metric|
        start_time = Time.current
        begin
          data[metric] = calculate_metric(metric)
        rescue StandardError => e
          data[metric] = {}
          Rails.logger.error "Error calculating metric #{metric}: #{e.message}"
        ensure
          @metric_timings[metric] = ((Time.current - start_time) * 1000).round(2)
        end
      end

      Rails.logger.info "Data calculated: #{data.inspect}"

      if @group_by.present?
        Rails.logger.info "Group by: #{@group_by.inspect}"
        case @group_by
        when 'agent'
          data[:grouped_data] = {
            grouped_by: 'agent'
          }
          @account.users.each do |user|
            data[:grouped_data][user.id] = {}
            @metrics.each do |metric|
              # Ensure data[metric] is not nil and has the expected structure
              if data[metric].nil?
                Rails.logger.warn "Metric #{metric} returned nil, setting to empty hash"
                data[metric] = {}
              end
              data[:grouped_data][user.id][metric] = data[metric][user.id]
            end
          end
        when 'inbox'
          data[:grouped_data] = {
            grouped_by: 'inbox'
          }
          @account.inboxes.each do |inbox|
            data[:grouped_data][inbox.id] = {}
            @metrics.each do |metric|
              # Ensure data[metric] is not nil and has the expected structure
              if data[metric].nil?
                Rails.logger.warn "Metric #{metric} returned nil, setting to empty hash"
                data[metric] = {}
              end
              data[:grouped_data][inbox.id][metric] = data[metric][inbox.id]
            end
          end
        when 'working_hours'
          data[:grouped_data] = {
            grouped_by: 'working_hours'
          }
          @metrics.each do |metric|
            # Ensure data[metric] is not nil
            if data[metric].nil?
              Rails.logger.warn "Metric #{metric} returned nil, setting to empty hash"
              data[metric] = {}
            end
            data[:grouped_data][metric] = data[metric]
          end
        when 'labels'
          data[:grouped_data] = {
            grouped_by: 'labels'
          }

          @metrics.each do |metric|
            # Ensure data[metric] is not nil
            if data[metric].nil?
              Rails.logger.warn "Metric #{metric} returned nil, setting to empty hash"
              data[metric] = {}
            end
            data[:grouped_data][metric] = data[metric]
          end
        end

        # clean up metric objects
        # @metrics.each do |metric|
        #   data.delete(metric)
        # end
      end
    ensure
      log_metric_timings
    end

    {
      time_range: @filters[:time_period],
      data: data
    }
  end
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  private

  def calculate_metric(metric) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/AbcSize
    case metric
    when 'bot_orders_placed'
      bot_orders_placed(@account.id, @time_range, @flow_id)
    when 'live_chat_orders_placed'
      live_chat_orders_placed(@account.id, @time_range)
    when 'bot_revenue_generated'
      bot_revenue_generated(@account.id, @time_range, @flow_id)
    when 'live_chat_revenue_generated'
      live_chat_revenue_generated(@account.id, @time_range)
    when 'bot_total_revenue'
      bot_total_revenue(@account.id, @time_range, @flow_id)
    when 'live_chat_impressions'
      live_chat_impressions(@account.id, @time_range)
    when 'live_chat_widget_opened'
      live_chat_widget_opened(@account.id, @time_range)
    when 'live_chat_intent_match'
      live_chat_intent_match(@account.id, @time_range)
    when 'live_chat_fall_back'
      live_chat_fall_back(@account.id, @time_range)
    when 'live_chat_total_revenue'
      live_chat_total_revenue(@account.id, @time_range)
    when 'agent_revenue_generated'
      agent_revenue_generated(@account.id, @time_range)
    when 'agent_total_calls'
      agent_total_calls(@account.id, @time_range)
    when 'sales_ooo_hours'
      sales_ooo_hours(@account.id, @time_range, @flow_id)
    when 'live_chat_sales_ooo_hours'
      live_chat_sales_ooo_hours(@account.id, @time_range)
    else
      send(metric) if metric_valid?(metric)
    end
  end

  # rubocop:disable Metrics/MethodLength
  def metric_valid?(metric)
    %w[handled
       new_assigned
       open
       reopened
       resolved_in_pre_time_range
       resolved_in_time_range
       carry_forwarded
       resolved
       waiting_agent_response
       waiting_customer_response
       snoozed
       avg_first_response_time
       avg_resolution_time
       avg_resolution_time_of_new_assigned_conversations
       avg_resolution_time_of_carry_forwarded_conversations
       avg_resolution_time_of_reopened_conversations
       avg_resolution_time_of_time_range
       avg_resolution_time_of_pre_time_range
       avg_response_time
       avg_csat_score
       median_first_response_time
       median_resolution_time
       median_resolution_time_of_new_assigned_conversations
       median_resolution_time_of_carry_forwarded_conversations
       median_resolution_time_of_reopened_conversations
       median_response_time
       median_csat_score
       total_online_time
       bot_total_revenue
       sales_ooo_hours
       bot_handled
       bot_resolved
       bot_avg_resolution_time
       bot_assign_to_agent
       pre_sale_queries
       bot_orders_placed
       bot_revenue_generated
       live_chat_total_revenue
       live_chat_sales_ooo_hours
       live_chat_orders_placed
       live_chat_revenue_generated
       live_chat_impressions
       live_chat_widget_opened
       live_chat_intent_match
       live_chat_csat_metrics
       total_conversations
       total_calling_nudged_conversations
       scheduled_call_conversations
       not_picked_up_call_conversations
       follow_up_call_conversations
       converted_call_conversations
       ringing_no_response_conversations
       hung_up_after_intro_conversations
       conversation_happened_conversations
       asked_to_whatsapp_conversations
       already_purchased_conversations
       dont_want_conversations
       asked_to_call_later
       switched_off_conversations
       busy_tone_conversations
       pending_conversations
       query_resolved_conversations
       successfully_done_conversations
       call_back_conversations
       snooze_conversations
       other_conversations
       dropped_call_conversations
       avg_time_to_call_after_nudge
       avg_time_to_convert
       avg_time_to_drop
       avg_follow_up_calls
       total_inbound_calls_handled
       total_calls_missed
       inbound_calls_resolved
       total_inbound_call_conversations
       avg_call_handling_time
       conversation_with_label
       label_percentage
       avg_call_wait_time].include?(metric)
  end
  # rubocop:enable Metrics/MethodLength

  def log_metric_timings
    total_time = @metric_timings.values.sum

    timing_report = [
      "\n=== Metric Calculation Timings ===",
      "Total time: #{total_time.round(2)}ms",
      "\nIndividual metrics:",
      @metric_timings.sort_by { |_, time| -time }.map do |metric, time|
        "#{metric}: #{time}ms (#{((time / total_time) * 100).round(2)}%)"
      end
    ].flatten.join("\n")

    Rails.logger.info timing_report
  end
end
