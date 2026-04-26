# frozen_string_literal: true

# Converts the schema-form helper's nested params into the JSON shape expected
# by the agentic API. Strips blanks, coerces booleans/integers, and zips the
# `__keys__` / `__values__` parallel arrays emitted for dict-of-strings fields.
module Synapseos::AgenticPayloadBuilder
  extend ActiveSupport::Concern

  private

  def build_payload_from_params(value)
    case value
    when ActionController::Parameters
      build_payload_from_params(value.to_unsafe_h)
    when Hash
      build_hash_payload(value)
    when Array
      value.map { |v| build_payload_from_params(v) }.reject { |v| v.nil? || v == '' }
    else
      coerce_scalar(value)
    end
  end

  def build_hash_payload(hash)
    return zip_dict_pairs(hash) if hash.key?('__keys__') || hash.key?(:__keys__)

    hash.each_with_object({}) do |(k, v), acc|
      converted = build_payload_from_params(v)
      next if converted.nil?
      next if converted.is_a?(String) && converted.empty?

      acc[k.to_s] = converted
    end
  end

  def zip_dict_pairs(hash)
    keys = Array(hash['__keys__'] || hash[:__keys__])
    values = Array(hash['__values__'] || hash[:__values__])
    keys.zip(values).each_with_object({}) do |(k, v), acc|
      next if k.to_s.strip.empty?

      acc[k.to_s] = v.to_s
    end
  end

  def coerce_scalar(value)
    return nil if value.nil?
    return value unless value.is_a?(String)

    stripped = value.strip
    return nil if stripped.empty?
    return true if stripped == 'true'
    return false if stripped == 'false'
    return Integer(stripped) if stripped.match?(/\A-?\d+\z/)

    stripped
  end
end
