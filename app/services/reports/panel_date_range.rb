class Reports::PanelDateRange
  def self.resolve(preset, custom_since: nil, custom_until: nil)
    if preset.to_s == 'custom' && custom_since.present? && custom_until.present?
      since_time = Time.zone.at(custom_since.to_i)
      until_time = Time.zone.at(custom_until.to_i)
      return [since_time, until_time] if since_time <= until_time
    end

    now = Time.zone.now
    case preset.to_s
    when 'today'
      [now.beginning_of_day, now.end_of_day]
    when 'yesterday'
      day = 1.day.ago
      [day.beginning_of_day, day.end_of_day]
    when 'last_30_days'
      [30.days.ago.beginning_of_day, now.end_of_day]
    else
      [7.days.ago.beginning_of_day, now.end_of_day]
    end
  end
end
