require 'rubygems'
require 'active_support/all'
require 'i18n'

class Time
  def self.diff(start_date, end_date, format_string='%y, %M, %w, %d and %h:%m:%s')
    #I18n.load_path += Dir.glob("lib/*.yml")
    start_time = start_date.to_time if start_date.respond_to?(:to_time)
    end_time = end_date.to_time if end_date.respond_to?(:to_time)
    distance_in_seconds = ((end_time - start_time).abs).round

    components = get_time_diff_components(%w(year month week day hour minute second), distance_in_seconds)
    time_diff_components = {:year => components[0], :month => components[1], :week => components[2], :day => components[3], :hour => components[4], :minute => components[5], :second => components[6]}

    formatted_intervals = get_formatted_intervals(format_string)
    components = get_time_diff_components(formatted_intervals, distance_in_seconds)
    formatted_components = create_formatted_component_hash(components, formatted_intervals)
    format_string = remove_format_string_for_zero_components(formatted_components, format_string)
    time_diff_components[:diff] = format_date_time(formatted_components, format_string) unless format_string.nil?
    return time_diff_components
  end

  def self.get_formatted_intervals(format_string)
    intervals = []
    intervals << 'year' if format_string.include?('%y')
    intervals << 'month' if format_string.include?('%M')
    intervals << 'week' if format_string.include?('%w')
    intervals << 'day' if format_string.include?('%d')
    intervals << 'hour' if format_string.include?('%h') || format_string.include?('%H')
    intervals << 'minute' if format_string.include?('%m') || format_string.include?('%N')
    intervals << 'second' if format_string.include?('%s') || format_string.include?('%S')
    intervals
  end

  def self.create_formatted_component_hash(components, formatted_intervals)
    formatted_components = {}
    index = 0
    components.each do |component|
      formatted_components[:"#{formatted_intervals[index]}"] = component
      index = index + 1
    end
    formatted_components
  end

  def self.get_time_diff_components(intervals, distance_in_seconds)
    components = []
    intervals.each do |interval|
        component = (distance_in_seconds / 1.send(interval)).floor
        distance_in_seconds -= component.send(interval)
        components << component
    end
    components
  end

  def Time.format_date_time(time_diff_components, format_string)
    format_string.gsub!('%y', "#{time_diff_components[:year]} #{pluralize('year', time_diff_components[:year])}") if time_diff_components[:year] 
    format_string.gsub!('%M', "#{time_diff_components[:month]} #{pluralize('month', time_diff_components[:month])}") if time_diff_components[:month]
    format_string.gsub!('%w', "#{time_diff_components[:week]} #{pluralize('week', time_diff_components[:week])}") if time_diff_components[:week]
    format_string.gsub!('%d', "#{time_diff_components[:day]} #{pluralize('day', time_diff_components[:day])}") if time_diff_components[:day]
    format_string.gsub!('%H', "#{time_diff_components[:hour]} #{pluralize('hour', time_diff_components[:hour])}") if time_diff_components[:hour]
    format_string.gsub!('%N', "#{time_diff_components[:minute]} #{pluralize('minute', time_diff_components[:minute])}") if time_diff_components[:minute]
    format_string.gsub!('%S', "#{time_diff_components[:second]} #{pluralize('second', time_diff_components[:second])}") if time_diff_components[:second]
    format_string.gsub!('%h', format_digit(time_diff_components[:hour]).to_s) if time_diff_components[:hour]
    format_string.gsub!('%m', format_digit(time_diff_components[:minute]).to_s) if time_diff_components[:minute]
    format_string.gsub!('%s', format_digit(time_diff_components[:second]).to_s) if time_diff_components[:second]
    format_string
  end

  def Time.pluralize(word, count)
    return count != 1 ? I18n.t(word.pluralize, :default => word.pluralize) : I18n.t(word, :default =>  word)
  end

  def Time.remove_format_string_for_zero_components(time_diff_components, format_string)
    format_string.gsub!('%y, ','') if time_diff_components[:year] == 0
    format_string.gsub!('%M, ','') if time_diff_components[:month] == 0
    format_string.gsub!('%w, ','') if time_diff_components[:week] == 0
    if format_string.slice(0..1) == '%d'
      format_string.gsub!('%d ','') if time_diff_components[:day] == 0
    else
      format_string.gsub!(', %d','') if time_diff_components[:day] == 0
    end
    format_string.slice!(0..3) if format_string.slice(0..3) == 'and ' 
    format_string
  end

  def Time.format_digit(number)
    return '%02d' % number
  end
end
