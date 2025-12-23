# frozen_string_literal: true

module Twilio
  def self.serialize_iso8601_date(date)
    if date.eql?(:unset)
      date
    elsif date.is_a?(Date)
      date.iso8601
    elsif date.is_a?(Time)
      date.strftime('%Y-%m-%d')
    elsif date.is_a?(String)
      date
    end
  end

  def self.serialize_iso8601_datetime(date)
    if date.eql?(:unset)
      date
    elsif date.is_a?(Date)
      Time.new(date.year, date.month, date.day).utc.iso8601
    elsif date.is_a?(Time)
      date.utc.iso8601
    elsif date.is_a?(String)
      date
    end
  end

  def self.deserialize_rfc2822(date)
    Time.rfc2822(date) unless date.nil?
  end

  def self.deserialize_iso8601_date(date)
    Date.parse(date) unless date.nil?
  end

  def self.deserialize_iso8601_datetime(date)
    Time.parse(date) unless date.nil?
  end

  def self.serialize_object(object)
    if object.is_a?(Hash) || object.is_a?(Array)
      JSON.generate(object)
    else
      object
    end
  end

  def self.flatten(map, result = {}, previous = [])
    map.each do |key, value|
      if value.is_a? Hash
        self.flatten(value, result, previous + [key])
      else
        result[(previous + [key]).join('.')] = value
      end
    end

    result
  end

  def self.prefixed_collapsible_map(map, prefix)
    result = {}
    if map.is_a? Hash
      flattened = self.flatten(map)
      result = {}
      flattened.each do |key, value|
        result[prefix + '.' + key] = value
      end
    end

    result
  end

  def self.serialize_list(input_list)
    return input_list unless input_list.is_a? Array
    result = []
    input_list.each do |e|
      result.push yield e
    end
    result
  end
end
