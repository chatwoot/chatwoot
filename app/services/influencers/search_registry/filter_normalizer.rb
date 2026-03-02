require 'digest'

class Influencers::SearchRegistry::FilterNormalizer
  def initialize(filter_params)
    @filter_params = filter_params || {}
  end

  def perform
    normalize_hash(@filter_params)
  end

  def signature
    Digest::SHA256.hexdigest(JSON.generate(perform))
  end

  private

  def normalize_hash(value)
    value.to_h.each_with_object({}) do |(key, raw_value), normalized|
      normalized_value = normalize_value(raw_value)
      normalized[key.to_s] = normalized_value unless blank_value?(normalized_value)
    end.sort.to_h
  end

  def normalize_array(value)
    normalized_items = value.filter_map do |item|
      normalized_item = normalize_value(item)
      normalized_item unless blank_value?(normalized_item)
    end

    normalized_items.sort_by { |item| JSON.generate(item) }
  end

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
  def normalize_value(value)
    case value
    when ActionController::Parameters
      normalize_hash(value.to_unsafe_h)
    when Hash
      normalize_hash(value)
    when Array
      normalize_array(value)
    when String
      normalize_string(value)
    when Symbol
      value.to_s
    when Integer
      value
    when Float, BigDecimal
      value.to_f
    when NilClass
      nil
    else
      if value.respond_to?(:to_i) && numeric_string?(value)
        value.to_i
      elsif value.respond_to?(:to_f) && decimal_string?(value)
        value.to_f
      else
        value
      end
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

  def normalize_string(value)
    normalized = value.strip
    return if normalized.blank?

    return normalized.to_i if numeric_string?(normalized)
    return normalized.to_f if decimal_string?(normalized)

    normalized
  end

  def blank_value?(value)
    value.respond_to?(:blank?) ? value.blank? : value.nil?
  end

  def numeric_string?(value)
    value.is_a?(String) && value.match?(/\A-?\d+\z/)
  end

  def decimal_string?(value)
    value.is_a?(String) && value.match?(/\A-?\d+\.\d+\z/)
  end
end
