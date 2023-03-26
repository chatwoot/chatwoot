module Api::V2::Accounts::HeatmapHelper
  def generate_conversations_heatmap_report
    utc_data = generate_heatmap_data_for_utc
    # we cannot convert the UTC data, because the data has a 60 min granularity

    # while timezones have a 30 min granularity
    timezone_data = generate_heatmap_data_for_timezone(params[:timezone_offset])

    {
      utc: group_traffic_data(utc_data),
      timezone: group_traffic_data(timezone_data)
    }
  end

  private

  def group_traffic_data(data)
    result_arr = []

    dates = data.pluck(:date).uniq.sort # Get unique dates in ascending order

    result_arr << ([nil] + dates)

    data.group_by { |d| d[:hour] }.each do |hour, items| # Group data by hour
      row = [hour]
      grouped_values = items.group_by { |d| d[:date] }
      dates.each do |date|
        row << (grouped_values[date][0][:value] if grouped_values[date].is_a?(Array))
      end

      result_arr << row
    end

    result_arr
  end

  def generate_heatmap_data_for_utc
    today = DateTime.now.utc.beginning_of_day
    utc_data_raw = generate_heatmap_data(today, nil)

    transform_data(utc_data_raw, true)
  end

  def generate_heatmap_data_for_timezone(offset)
    timezone = ActiveSupport::TimeZone[offset]&.name
    timezone_today = DateTime.now.in_time_zone(timezone).beginning_of_day

    timezone_data_raw = generate_heatmap_data(timezone_today, offset)

    transform_data(timezone_data_raw, false)
  end

  def generate_heatmap_data(date, offset)
    report_params = {
      type: :account,
      group_by: 'hour',
      metric: 'conversations_count',
      business_hours: false
    }

    V2::ReportBuilder.new(Current.account, report_params.merge({
                                                                 since: since_timestamp(date),
                                                                 until: until_timestamp(date),
                                                                 timezone_offset: offset
                                                               })).build
  end

  def transform_data(data, zone_transform)
    # rubocop:disable Rails/TimeZone
    data.map do |d|
      date = zone_transform ? Time.zone.at(d[:timestamp]) : Time.at(d[:timestamp])
      {
        date: date.to_date.to_s,
        hour: date.hour,
        value: d[:value]
      }
    end
    # rubocop:enable Rails/TimeZone
  end

  def since_timestamp(date)
    (date - 7.days).to_i.to_s
  end

  def until_timestamp(date)
    date.to_i.to_s
  end
end
