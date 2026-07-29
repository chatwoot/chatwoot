# frozen_string_literal: true

# Normalizes ConditionRow values so `{ id, name }` becomes `["id"]`.
module BusinessRules::ConditionValues
  module_function

  def normalize(raw)
    case raw
    when nil
      []
    when Array
      raw.flat_map { |item| normalize(item) }
    when Hash, ActionController::Parameters
      hash = raw.respond_to?(:to_unsafe_h) ? raw.to_unsafe_h : raw.to_h
      hash = hash.with_indifferent_access
      pick = hash[:id].presence || hash[:name].presence || hash[:title].presence || hash[:value].presence
      pick.nil? ? [] : [pick.to_s]
    else
      raw.to_s.strip.empty? ? [] : [raw.to_s]
    end
  end
end
