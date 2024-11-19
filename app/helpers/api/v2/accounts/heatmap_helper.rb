module Api::V2::Accounts::HeatmapHelper
  def generate_conversations_heatmap_report
    timezone_data = generate_heatmap_data_for_timezone(params[:timezone_offset])

    group_traffic_data(timezone_data)
  end

  private

  def group_traffic_data(data)
    # start with an empty array
    result_arr = []

    # pick all the unique dates from the data in ascending order
    dates = data.pluck(:date).uniq.sort

    # add the dates as the first row, leave an empty cell for the hour column
    # e.g. ['Start of the hour', '2023-01-01', '2023-1-02', '2023-01-03']
    result_arr << (['Start of the hour'] + dates)

    # group the data by hour, we do not need to sort it, because the data is already sorted
    # given it starts from the beginning of the day
    # here each hour is a key, and the value is an array of all the items for that hour at each date
    # e.g. hour = 1
    # value = [{date: 2023-01-01, value: 1}, {date: 2023-01-02, value: 1}, {date: 2023-01-03, value: 1}, ...]
    data.group_by { |d| d[:hour] }.each do |hour, items|
      # create a new row for each hour
      row = [format('%02d:00', hour)]

      # group the items by date, so we can easily access the value for each date
      # grouped values will be a hasg with the date as the key, and the value as the value
      # e.g. { '2023-01-01' => [{date: 2023-01-01, value: 1}], '2023-01-02' => [{date: 2023-01-02, value: 1}], ... }
      grouped_values = items.group_by { |d| d[:date] }

      # now for each unique date we have, we can access the value for that date and append it to the array
      dates.each do |date|
        row << (grouped_values[date][0][:value] if grouped_values[date].is_a?(Array))
      end

      # row will look like ['22:00', 0, 0, 1, 4, 6, 7, 4]
      # add the row to the result array

      result_arr << row
    end

    # return the resultant array
    # the result looks like this
    # [
    #   ['Start of the hour', '2023-01-01', '2023-1-02', '2023-01-03'],
    #   ['00:00', 0, 0, 0],
    #   ['01:00', 0, 0, 0],
    #   ['02:00', 0, 0, 0],
    #   ['03:00', 0, 0, 0],
    #   ['04:00', 0, 0, 0],
    # ]
    result_arr
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
    (date - 6.days).to_i.to_s
  end

  def until_timestamp(date)
    date.to_i.to_s
  end
end
