require 'scheme'

module Captain::Apropos::SchemeValues
  PROCEDURES = [::Scheme::Native, ::Scheme::Closure, ::Scheme::CaseClosure, ::Scheme::Continuation, ::Scheme::Parameter].freeze

  def self.procedure?(value) = PROCEDURES.any? { |type| value.is_a?(type) }

  def self.from_ruby(value)
    case value
    when Array then ::Scheme.list(value.map { |item| from_ruby(item) })
    when Hash then value.transform_values { |item| from_ruby(item) }
    else value
    end
  end

  def self.to_ruby(value, seen = {}.compare_by_identity)
    return [] if value.equal?(::Scheme::EMPTY)
    return nil if value.equal?(::Scheme::UNSPECIFIED)
    return value unless value.is_a?(::Scheme::Pair) || value.is_a?(Hash) || value.is_a?(Array) || value.is_a?(::Scheme::Vector)
    raise Captain::Apropos::Error, 'Tool data must be acyclic JSON-shaped values' if seen[value]

    seen[value] = true
    case value
    when ::Scheme::Pair then ::Scheme.to_a(value).map { |item| to_ruby(item, seen) }
    when ::Scheme::Vector then value.items.map { |item| to_ruby(item, seen) }
    when Array then value.map { |item| to_ruby(item, seen) }
    when Hash then value.transform_values { |item| to_ruby(item, seen) }
    end
  ensure
    seen.delete(value) if seen
  end

  def self.describe_value(value)
    to_ruby(value)
  rescue ::Scheme::Error, Captain::Apropos::Error
    { 'type' => value.class.name }
  end

  def self.expression(value)
    to_ruby(value)
  rescue ::Scheme::Error, Captain::Apropos::Error
    :expression
  end
end
