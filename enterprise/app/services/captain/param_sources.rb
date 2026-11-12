# Where Chatwoot reads a tool parameter's value instead of asking the model. A tool stores one entry per parameter,
# such as { "email" => { "source" => "verified.email" } } or { "limit" => { "source" => "fixed", "value" => "20" } }.
module Captain::ParamSources
  VERIFIED_EMAIL = 'verified.email'.freeze
  FIXED = 'fixed'.freeze
  # The keys of each source's entry. Every value is a string.
  SHAPES = { VERIFIED_EMAIL => %w[source], FIXED => %w[source value] }.freeze
  UNVERIFIED = 'This tool needs a verified email, and this customer has not verified an email yet. ' \
               'Verify their email with a one-time code first, then call this tool again. ' \
               'If that is not possible, ask whether they want to talk to a support agent.'.freeze
  # Added to a result when an admin or an agent passed a proven value the customer did not prove
  UNVERIFIED_VALUE_NOTE = 'The email passed to this tool was not verified by the customer.'.freeze
  # A fixed value is stored as text. A parameter of one of these JSON types gets the value in that type.
  FIXED_TYPES = {
    'integer' => ->(text) { Integer(text, 10) },
    'number' => ->(text) { Float(text) },
    'boolean' => ->(text) { { 'true' => true, 'false' => false }.fetch(text.strip.downcase) }
  }.freeze

  # The message tells the model why the value is missing and what to do next
  class Unavailable < StandardError; end

  # Errors for a tool's entries, checked against the parameters in its input schema
  def self.validate(entries, properties:, tool_name:)
    return [I18n.t('captain.param_sources.invalid', tool: tool_name)] unless entries.is_a?(Hash)

    unknown = entries.keys - properties.keys
    return [I18n.t('captain.param_sources.unknown_param', tool: tool_name, names: unknown.join(', '))] if unknown.any?

    errors = entries.filter_map do |param, entry|
      type = property_type(properties[param])
      problem = entry_problem(entry) || fixed_type_problem(entry, type)
      I18n.t("captain.param_sources.#{problem}", tool: tool_name, name: param, type: type) if problem
    end
    errors.presence || verified_email_errors(entries, properties, tool_name)
  end

  # Whether the customer proves the value, so a tool that uses it runs only for a verified customer
  def self.proven?(entry)
    entry['source'] == VERIFIED_EMAIL
  end

  # The JSON type of a parameter in an input schema. A nullable parameter has one type besides null, written as a type
  # list or as anyOf or oneOf branches, as MCP SDKs describe optional parameters. Any other shape has no single type, so a
  # fixed value for it stays text.
  def self.property_type(property)
    return unless property.is_a?(Hash)

    types = (declared_types(property) - ['null']).uniq
    types.first if types.one?
  end

  # Raises Unavailable when the value cannot be read for this conversation. A fixed value takes the parameter's type.
  def self.resolve(entry, conversation, type: nil)
    case entry['source']
    when VERIFIED_EMAIL then verified_email(conversation)
    when FIXED then fixed_value(entry['value'], type)
    end
  end

  # The email the customer verified in this conversation, or nil. It is read from stored data on every call, never from
  # the run state the model can influence.
  def self.stored_verified_email(conversation)
    conversation && Captain::EmailVerification.new(conversation).verified_email
  end

  def self.verified_email(conversation)
    stored_verified_email(conversation) || raise(Unavailable, UNVERIFIED)
  end

  # Each source has an exact shape, so an unknown source, an extra key or a value of the wrong type is invalid
  def self.entry_problem(entry)
    shape = entry.is_a?(Hash) && SHAPES[entry['source']]
    return :invalid_source unless shape && entry.keys.sort == shape && entry.values.all?(String)

    :fixed_value_blank if entry['source'] == FIXED && entry['value'].blank?
  end
  private_class_method :entry_problem

  def self.declared_types(property)
    branches = property['anyOf'] || property['oneOf']
    return Array(property['type']) unless branches.is_a?(Array)

    branches.select { |branch| branch.is_a?(Hash) }.flat_map { |branch| Array(branch['type']) }
  end
  private_class_method :declared_types

  def self.fixed_value(text, type)
    convert = FIXED_TYPES[type]
    convert ? convert.call(text) : text
  end
  private_class_method :fixed_value

  # A fixed value must convert to its parameter's type, so a call never sends a value of the wrong type
  def self.fixed_type_problem(entry, type)
    return unless entry['source'] == FIXED

    fixed_value(entry['value'], type)
    nil
  rescue ArgumentError, KeyError
    :fixed_value_type
  end
  private_class_method :fixed_type_problem

  def self.verified_email_errors(entries, properties, tool_name)
    verified = entries.select { |_param, entry| proven?(entry) }.keys
    return [I18n.t('captain.param_sources.one_verified_email', tool: tool_name)] if verified.size > 1
    # Verified values are text, so a parameter that takes one must be a string
    return [] if verified.none? || properties.dig(verified.first, 'type') == 'string'

    [I18n.t('captain.param_sources.verified_email_type', tool: tool_name, name: verified.first)]
  end
  private_class_method :verified_email_errors
end
