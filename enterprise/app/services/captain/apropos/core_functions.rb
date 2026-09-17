# Chatwoot extensions only. Standard names and semantics come from lib/scheme.
class Captain::Apropos::CoreFunctions
  DEFINITIONS = {
    'hash' => ['(hash "key" value ...)', 'Build an object from alternating string keys and values.', ->(*pairs) { build_hash(pairs) }],
    'get' => ['(get object "key")', 'Read a required field; missing keys are errors.', lambda { |object, key|
      typed(object, Hash).fetch(typed(key, String))
    }],
    'keys' => ['(keys object)', 'List the string keys of an object.', ->(object) { typed(object, Hash).keys }],
    'hash-values' => ['(hash-values object)', 'List object values. Scheme values is the standard multiple-values procedure.',
                      ->(object) { typed(object, Hash).values }],
    'has-key?' => ['(has-key? object "key")', 'Test field presence, including null values.',
                   ->(object, key) { typed(object, Hash).key?(typed(key, String)) }],
    'hash-set' => ['(hash-set object "key" value)', 'Return an object with one field replaced; do not mutate the input.',
                   ->(object, key, value) { typed(object, Hash).merge(typed(key, String) => value) }],
    'hash-merge' => ['(hash-merge left right)', 'Merge objects, with right-side fields winning.',
                     ->(left, right) { typed(left, Hash).merge(typed(right, Hash)) }],
    'nil?' => ['(nil? value)', 'Test database/JSON null. Empty lists and false are different.', ->(value) { value.nil? }],
    'hash?' => ['(hash? value)', 'Test for a Chatwoot object.', ->(value) { value.is_a?(Hash) }],
    'string-contains?' => ['(string-contains? text part)', 'Test for a literal substring.',
                           ->(text, part) { typed(text, String).include?(typed(part, String)) }],
    'string-split' => ['(string-split text separator)', 'Split by a nonempty literal separator, preserving empty pieces.',
                       ->(text, separator) { split_string(text, separator) }],
    'string-join' => ['(string-join texts separator)', 'Join a list of strings.',
                      ->(texts, separator) { typed(texts, Array).each { |text| typed(text, String) }.join(typed(separator, String)) }],
    'string-trim' => ['(string-trim text)', 'Remove leading and trailing whitespace.', ->(text) { typed(text, String).strip }]
  }.freeze

  def self.install(scheme)
    DEFINITIONS.each { |name, (_signature, _description, implementation)| scheme.register(name, &implementation) }
  end

  def self.contracts
    DEFINITIONS.transform_values { |signature, description, _implementation| [signature, description] }
  end

  def self.typed(value, *types)
    return value if types.any? { |type| value.is_a?(type) }

    raise Captain::Apropos::Error, "Expected #{types.map(&:name).join(' or ')}, got #{value.class.name}"
  end

  def self.build_hash(pairs)
    raise Captain::Apropos::Error, 'hash expects alternating string keys and values' if pairs.size.odd?

    pairs.each_slice(2).to_h { |key, value| [typed(key, String), value] }
  end

  def self.split_string(text, separator)
    typed(text, String)
    typed(separator, String)
    raise Captain::Apropos::Error, 'Separator must not be empty' if separator.empty?

    text.split(Regexp.new(Regexp.escape(separator)), -1)
  end
end
