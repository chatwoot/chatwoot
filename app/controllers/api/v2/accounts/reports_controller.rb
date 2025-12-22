class Api::V2::Accounts::ReportsController < Api::V1::Accounts::BaseController
  include Api::V2::Accounts::ReportsHelper
  include Api::V2::Accounts::HeatmapHelper

  before_action :check_authorization

  def index
    builder = V2::Reports::Conversations::ReportBuilder.new(Current.account, report_params)
    data = builder.timeseries
    render json: data
  end

  def summary
    render json: build_summary(:summary)
  end

  def bot_summary
    render json: build_summary(:bot_summary)
  end

  def agents
    @report_data = generate_agents_report
    generate_csv('agents_report', 'api/v2/accounts/reports/agents')
  end

  def inboxes
    @report_data = generate_inboxes_report
    generate_csv('inboxes_report', 'api/v2/accounts/reports/inboxes')
  end

  def labels
    @report_data = generate_labels_report
    generate_csv('labels_report', 'api/v2/accounts/reports/labels')
  end

  def teams
    @report_data = generate_teams_report
    generate_csv('teams_report', 'api/v2/accounts/reports/teams')
  end

  def conversation_traffic
    @report_data = generate_conversations_heatmap_report
    timezone_offset = (params[:timezone_offset] || 0).to_f
    @timezone = ActiveSupport::TimeZone[timezone_offset]

    generate_csv('conversation_traffic_reports', 'api/v2/accounts/reports/conversation_traffic')
  end

  def conversations
    return head :unprocessable_entity if params[:type].blank?

    render json: conversation_metrics
  end

  def bot_metrics
    bot_metrics = V2::Reports::BotMetricsBuilder.new(Current.account, params).metrics
    render json: bot_metrics
  end

  def booking_stats
    period = determine_period_from_params

    service = Dealership::BookingStatsService.new(
      Current.account.dealership_id,
      period: period,
      since: params[:since],
      until_time: params[:until]
    )
    booking_data = service.fetch_stats

    filtered_data = filter_by_date_range(booking_data, params[:since], params[:until])
    formatted_data = format_booking_breakdown_data(filtered_data, period)

    # Fill in missing dates with zeros to show complete timeline
    formatted_data = fill_missing_dates_with_zeros(formatted_data, params[:since], params[:until], period)

    render json: formatted_data
  end

  def booking_summary
    render json: build_booking_summary
  end

  private

  def filter_by_date_range(booking_data, since_timestamp, until_timestamp)
    return booking_data unless since_timestamp && until_timestamp

    data_array = booking_data[:data] || booking_data['data'] || []
    return booking_data if data_array.empty?

    since_date = date_from_timestamp(since_timestamp)
    until_date = date_from_timestamp(until_timestamp)
    period = booking_data[:period] || booking_data['period']

    filtered = data_array.select do |item|
      item_date = parse_item_date(item, period)
      item_date && item_date.between?(since_date, until_date)
    end

    { data: filtered, period: period }
  end

  def parse_item_date(item, period)
    case period
    when 'daily'
      Date.parse(item['date']) if item['date']
    when 'weekly'
      parts = item['week']&.split('-')
      Date.parse("#{parts[0]}-#{parts[1]}-#{Time.current.year}") if parts&.size&.>= 2
    when 'monthly'
      Date.parse("#{item['month']}-01") if item['month']
    end
  rescue StandardError
    nil
  end

  def determine_period_from_params
    case params[:group_by]&.to_s
    when 'week' then 'weekly'
    when 'month' then 'monthly'
    else 'daily'
    end
  end

  def format_booking_breakdown_data(booking_data, period)
    data_array = booking_data[:data] || booking_data['data'] || []

    data_array.map do |item|
      breakdown = item['booking_type_breakdown'] || {}
      booking_data = breakdown['booking'] || {}
      handoff_data = breakdown['handoff'] || {}

      {
        timestamp: parse_timestamp(item, period),
        booking_links_sent: booking_data['links_sent'] || 0,
        booking_forms_completed: booking_data['forms_completed'] || 0,
        handoff_links_sent: handoff_data['links_sent'] || 0,
        handoff_forms_completed: handoff_data['forms_completed'] || 0
      }
    end
  end

  def parse_timestamp(item, period)
    case period
    when 'daily'
      Date.parse(item['date']).to_time.to_i if item['date']
    when 'weekly'
      parse_week_timestamp(item['week']) if item['week']
    when 'monthly'
      Date.parse("#{item['month']}-01").to_time.to_i if item['month']
    end
  rescue StandardError
    Time.current.to_i
  end

  def parse_week_timestamp(week_string)
    parts = week_string.split('-')
    Date.parse("#{parts[0]}-#{parts[1]}-#{Time.current.year}").to_time.to_i
  rescue StandardError
    Time.current.to_i
  end

  def generate_placeholder_data(since_timestamp, until_timestamp, period)
    since_date = date_from_timestamp(since_timestamp)
    until_date = date_from_timestamp(until_timestamp)

    case period
    when 'weekly'
      generate_weekly_placeholders(since_date, until_date)
    when 'monthly'
      generate_monthly_placeholders(since_date, until_date)
    else
      generate_daily_placeholders(since_date, until_date)
    end
  end

  def generate_placeholder_breakdown_data(since_timestamp, until_timestamp, period)
    since_date = date_from_timestamp(since_timestamp)
    until_date = date_from_timestamp(until_timestamp)

    case period
    when 'weekly'
      generate_weekly_breakdown_placeholders(since_date, until_date)
    when 'monthly'
      generate_monthly_breakdown_placeholders(since_date, until_date)
    else
      generate_daily_breakdown_placeholders(since_date, until_date)
    end
  end

  def generate_daily_breakdown_placeholders(since_date, until_date)
    (since_date..until_date).map do |date|
      {
        timestamp: date.to_time.to_i,
        booking_links_sent: 0,
        booking_forms_completed: 0,
        handoff_links_sent: 0,
        handoff_forms_completed: 0
      }
    end
  end

  def generate_weekly_breakdown_placeholders(since_date, until_date)
    current = since_date.beginning_of_week
    placeholders = []
    while current <= until_date
      placeholders << {
        timestamp: current.to_time.to_i,
        booking_links_sent: 0,
        booking_forms_completed: 0,
        handoff_links_sent: 0,
        handoff_forms_completed: 0
      }
      current += 1.week
    end
    placeholders
  end

  def generate_monthly_breakdown_placeholders(since_date, until_date)
    current = since_date.beginning_of_month
    placeholders = []
    while current <= until_date
      placeholders << {
        timestamp: current.to_time.to_i,
        booking_links_sent: 0,
        booking_forms_completed: 0,
        handoff_links_sent: 0,
        handoff_forms_completed: 0
      }
      current += 1.month
    end
    placeholders
  end

  def fill_missing_dates_with_zeros(formatted_data, since_timestamp, until_timestamp, period)
    return formatted_data if since_timestamp.blank? || until_timestamp.blank?

    # Generate all expected timestamps for the range
    expected_timestamps = case period
                          when 'weekly'
                            generate_weekly_timestamps(since_timestamp, until_timestamp)
                          when 'monthly'
                            generate_monthly_timestamps(since_timestamp, until_timestamp)
                          else
                            generate_daily_timestamps(since_timestamp, until_timestamp)
                          end

    # If no data exists, generate all zeros for the range
    if formatted_data.empty?
      return expected_timestamps.map do |timestamp|
        {
          timestamp: timestamp,
          booking_links_sent: 0,
          booking_forms_completed: 0,
          handoff_links_sent: 0,
          handoff_forms_completed: 0
        }
      end
    end

    # Create hash map of existing data by timestamp
    data_map = formatted_data.index_by { |item| item[:timestamp] }

    # Fill in missing dates with zeros
    expected_timestamps.map do |timestamp|
      data_map[timestamp] || {
        timestamp: timestamp,
        booking_links_sent: 0,
        booking_forms_completed: 0,
        handoff_links_sent: 0,
        handoff_forms_completed: 0
      }
    end
  end

  def generate_daily_timestamps(since_timestamp, until_timestamp)
    since_date = date_from_timestamp(since_timestamp)
    until_date = date_from_timestamp(until_timestamp)
    Time.use_zone(reports_timezone_name) do
      (since_date..until_date).map { |date| Time.zone.local(date.year, date.month, date.day).to_i }
    end
  end

  def generate_weekly_timestamps(since_timestamp, until_timestamp)
    since_date = date_from_timestamp(since_timestamp).beginning_of_week
    until_date = date_from_timestamp(until_timestamp)
    Time.use_zone(reports_timezone_name) do
      timestamps = []
      current = since_date
      while current <= until_date
        timestamps << Time.zone.local(current.year, current.month, current.day).to_i
        current += 1.week
      end
      timestamps
    end
  end

  def generate_monthly_timestamps(since_timestamp, until_timestamp)
    since_date = date_from_timestamp(since_timestamp).beginning_of_month
    until_date = date_from_timestamp(until_timestamp)
    Time.use_zone(reports_timezone_name) do
      timestamps = []
      current = since_date
      while current <= until_date
        timestamps << Time.zone.local(current.year, current.month, current.day).to_i
        current += 1.month
      end
      timestamps
    end
  end

  def generate_csv(filename, template)
    response.headers['Content-Type'] = 'text/csv'
    response.headers['Content-Disposition'] = "attachment; filename=#{filename}.csv"
    render layout: false, template: template, formats: [:csv]
  end

  def check_authorization
    authorize :report, :view?
  end

  def common_params
    {
      type: params[:type].to_sym,
      id: params[:id],
      group_by: params[:group_by],
      business_hours: ActiveModel::Type::Boolean.new.cast(params[:business_hours])
    }
  end

  def current_summary_params
    common_params.merge({
                          since: range[:current][:since],
                          until: range[:current][:until],
                          timezone_offset: params[:timezone_offset]
                        })
  end

  def previous_summary_params
    common_params.merge({
                          since: range[:previous][:since],
                          until: range[:previous][:until],
                          timezone_offset: params[:timezone_offset]
                        })
  end

  def report_params
    common_params.merge({
                          metric: params[:metric],
                          since: params[:since],
                          until: params[:until],
                          timezone_offset: params[:timezone_offset]
                        })
  end

  def conversation_params
    {
      type: params[:type].to_sym,
      user_id: params[:user_id],
      page: params[:page].presence || 1
    }
  end

  def range
    {
      current: {
        since: params[:since],
        until: params[:until]
      },
      previous: {
        since: (params[:since].to_i - (params[:until].to_i - params[:since].to_i)).to_s,
        until: params[:since]
      }
    }
  end

  def build_summary(method)
    builder = V2::Reports::Conversations::MetricBuilder
    current_summary = builder.new(Current.account, current_summary_params).send(method)
    previous_summary = builder.new(Current.account, previous_summary_params).send(method)
    current_summary.merge(previous: previous_summary)
  end

  def conversation_metrics
    V2::ReportBuilder.new(Current.account, conversation_params).conversation_metrics
  end

  def build_booking_summary
    period = determine_period_from_params
    metric_type = params[:metric_type] || 'booking'

    # Get current period data
    current_service = Dealership::BookingStatsService.new(
      Current.account.dealership_id,
      period: period,
      since: params[:since],
      until_time: params[:until]
    )
    current_data = current_service.fetch_stats
    current_filtered = filter_by_date_range(current_data, params[:since], params[:until])

    # Get previous period data
    previous_service = Dealership::BookingStatsService.new(
      Current.account.dealership_id,
      period: period,
      since: range[:previous][:since],
      until_time: range[:previous][:until]
    )
    previous_data = previous_service.fetch_stats
    previous_filtered = filter_by_date_range(previous_data, range[:previous][:since], range[:previous][:until])

    # Calculate totals for links_sent and forms_completed
    current_links = sum_metric(current_filtered, metric_type, 'links_sent')
    current_forms = sum_metric(current_filtered, metric_type, 'forms_completed')
    previous_links = sum_metric(previous_filtered, metric_type, 'links_sent')
    previous_forms = sum_metric(previous_filtered, metric_type, 'forms_completed')

    {
      "#{metric_type}_links_sent".to_sym => current_links,
      "#{metric_type}_forms_completed".to_sym => current_forms,
      :previous => {
        "#{metric_type}_links_sent".to_sym => previous_links,
        "#{metric_type}_forms_completed".to_sym => previous_forms
      }
    }
  end

  def sum_metric(booking_data, metric_type, metric_field)
    data_array = booking_data[:data] || booking_data['data'] || []
    data_array.sum do |item|
      breakdown = item['booking_type_breakdown'] || {}
      type_data = breakdown[metric_type] || {}
      type_data[metric_field] || 0
    end
  end

  # ----- Timezone helpers for booking reports -----

  def reports_timezone_name
    offset = (params[:timezone_offset] || 0).to_f
    ActiveSupport::TimeZone[offset]&.name || Time.zone.name
  end

  def date_from_timestamp(timestamp)
    return nil if timestamp.blank?

    timezone_name = reports_timezone_name
    Rails.logger.info "🔍 date_from_timestamp: timestamp=#{timestamp}, timezone_offset=#{params[:timezone_offset]}, timezone_name=#{timezone_name}"

    Time.use_zone(timezone_name) do
      date = Time.zone.at(timestamp.to_i).to_date
      Rails.logger.info "🔍 Converted date: #{date}"
      date
    end
  end
end
