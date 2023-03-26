module Api::V2::Accounts::HeatmapHelper
  def generate_conversations_heatmap_report
    report_params = {
      type: :account,
      group_by: 'hour',
      metric: 'conversations_count',
      business_hours: false
    }

    utc_data = generate_heatmap_data_for_utc(report_params)
    timezone_data = generate_heatmap_data_for_timezone(params[:timezone_offset], report_params)

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

  def generate_heatmap_data_for_utc(report_params)
    today = DateTime.now.utc.beginning_of_day

    utc_data_raw = V2::ReportBuilder.new(Current.account, report_params.merge({
                                                                                since: (today - 7.days).to_i.to_s,
                                                                                until: today.to_i.to_s
                                                                              })).build

    utc_data_raw.map do |d|
      date = Time.zone.at(d[:timestamp])
      {
        date: date.to_date.to_s,
        hour: date.hour,
        value: d[:value]
      }
    end
  end

  def generate_heatmap_data_for_timezone(offset, report_params)
    timezone = ActiveSupport::TimeZone[offset]&.name
    timezone_today = DateTime.now.in_time_zone(timezone).beginning_of_day

    # we need to convert the data to the timezone of the account
    # so that the report is generated in the timezone of the account
    # and not in UTC
    #
    # we cannot convert the UTC data, because the data has a 60 min granularity
    # while timezones have a 30 min granularity
    timezone_data_raw = V2::ReportBuilder.new(Current.account, report_params.merge({
                                                                                     since: (timezone_today - 7.days).to_i.to_s,
                                                                                     until: timezone_today.to_i.to_s,
                                                                                     timezone_offset: offset
                                                                                   })).build

    # rubocop:disable Rails/TimeZone
    timezone_data_raw.map do |d|
      date = Time.at(d[:timestamp])
      {
        date: date.to_date.to_s,
        hour: date.hour,
        value: d[:value]
      }
    end
    # rubocop:enable Rails/TimeZone
  end
end
