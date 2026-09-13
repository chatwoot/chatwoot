class Captain::Apropos::CoreFunctions
  DEFINITIONS = {
    'list' => ['(list value ...)', 'Build a list.', ->(*values) { values }],
    'hash' => ['(hash "key" value ...)', 'Build a hash from alternating keys and values.', ->(*pairs) { build_hash(pairs) }],
    'get' => ['(get object "key")', 'Read a required field; missing keys are errors.', ->(object, key) { typed(object, Hash).fetch(key.to_s) }],
    'keys' => ['(keys object)', 'List the keys of a hash.', ->(object) { typed(object, Hash).keys }],
    'values' => ['(values object)', 'List the values of a hash in key order.', ->(object) { typed(object, Hash).values }],
    'has-key?' => ['(has-key? object "key")', 'Test whether a hash contains a key, even if its value is null.',
                   ->(object, key) { typed(object, Hash).key?(key.to_s) }],
    'hash-set' => ['(hash-set object "key" value)', 'Return a new hash with one field set; the original is unchanged.',
                   ->(object, key, value) { typed(object, Hash).merge(key.to_s => value) }],
    'hash-merge' => ['(hash-merge left right)', 'Return a new hash; right-side fields replace matching left-side fields.',
                     ->(left, right) { typed(left, Hash).merge(typed(right, Hash)) }],
    'car' => ['(car items)', 'First list item; an empty list is an error.', ->(items) { typed(items, Array).fetch(0) }],
    'cdr' => ['(cdr items)', 'List without its first item.', ->(items) { typed(items, Array).drop(1) }],
    'cons' => ['(cons value items)', 'Prepend a value to a proper list. Dotted pairs are not supported.',
               ->(value, items) { [value] + typed(items, Array) }],
    'reverse' => ['(reverse items)', 'Reverse a list without changing it.', ->(items) { typed(items, Array).reverse }],
    'list-ref' => ['(list-ref items index)', 'Read a zero-based list index; out-of-range indexes are errors.',
                   ->(items, index) { typed(items, Array).fetch(nonnegative(index)) }],
    'length' => ['(length value)', 'Length of a list, hash, or string.', ->(value) { typed(value, Array, Hash, String).length }],
    'null?' => ['(null? value)', 'True only for an empty list.', ->(value) { value == [] }],
    'nil?' => ['(nil? value)', 'True only for database/JSON null, not false or an empty list.', ->(value) { value.nil? }],
    'not' => ['(not value)', 'True only for false.', ->(value) { value == false }],
    'equal?' => ['(equal? left right)', 'Compare values, including lists and hashes.', ->(left, right) { left == right }],
    'string?' => ['(string? value)', 'Test for a string.', ->(value) { value.is_a?(String) }],
    'number?' => ['(number? value)', 'Test for a number.', ->(value) { value.is_a?(Numeric) }],
    'boolean?' => ['(boolean? value)', 'Test for true or false.', ->(value) { value == true || value == false }],
    'list?' => ['(list? value)', 'Test for a list.', ->(value) { value.is_a?(Array) }],
    'hash?' => ['(hash? value)', 'Test for a hash.', ->(value) { value.is_a?(Hash) }],
    'symbol?' => ['(symbol? value)', 'Test for a quoted Scheme symbol.', ->(value) { value.is_a?(Symbol) }],
    'procedure?' => ['(procedure? value)', 'Test for an available primitive or Scheme function.',
                     ->(value) { value.is_a?(Proc) || value.is_a?(Captain::Apropos::Scheme::Closure) }],
    'string-append' => ['(string-append text ...)', 'Concatenate strings. Does not coerce other values.',
                        ->(*texts) { texts.each { |text| typed(text, String) }.join }],
    'string-length' => ['(string-length text)', 'Number of characters, not bytes.', ->(text) { typed(text, String).length }],
    'string=?' => ['(string=? left right)', 'Compare two strings.', ->(left, right) { typed(left, String) == typed(right, String) }],
    'string-contains?' => ['(string-contains? text part)', 'Test for a literal substring.',
                           ->(text, part) { typed(text, String).include?(typed(part, String)) }],
    'string-split' => ['(string-split text separator)', 'Split by a nonempty literal separator, preserving empty pieces.',
                       ->(text, separator) { split_string(text, separator) }],
    'string-join' => ['(string-join texts separator)', 'Join a list of strings with a literal separator.',
                      ->(texts, separator) { typed(texts, Array).each { |text| typed(text, String) }.join(typed(separator, String)) }],
    'substring' => ['(substring text start end)', 'Character slice from start inclusive to end exclusive; bounds must be valid.',
                    ->(text, start, finish) { substring(text, start, finish) }],
    'string-trim' => ['(string-trim text)', 'Remove leading and trailing whitespace.', ->(text) { typed(text, String).strip }],
    'string-downcase' => ['(string-downcase text)', 'Return lowercase text.', ->(text) { typed(text, String).downcase }],
    'string-upcase' => ['(string-upcase text)', 'Return uppercase text.', ->(text) { typed(text, String).upcase }],
    'number->string' => ['(number->string number)', 'Convert a number to decimal text.', ->(number) { typed(number, Numeric).to_s }],
    'string->number' => ['(string->number text)', 'Parse a decimal integer or fraction; return false for invalid text.',
                         ->(text) { parse_number(text) }]
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

  def self.nonnegative(value)
    return value if value.is_a?(Integer) && value >= 0

    raise Captain::Apropos::Error, 'Expected a nonnegative integer'
  end

  def self.build_hash(pairs)
    raise Captain::Apropos::Error, 'hash expects alternating keys and values' if pairs.size.odd?

    pairs.each_slice(2).to_h.transform_keys(&:to_s)
  end

  def self.split_string(text, separator)
    typed(text, String)
    typed(separator, String)
    raise Captain::Apropos::Error, 'Separator must not be empty' if separator.empty?

    text.split(Regexp.new(Regexp.escape(separator)), -1)
  end

  def self.substring(text, start, finish)
    typed(text, String)
    nonnegative(start)
    nonnegative(finish)
    raise Captain::Apropos::Error, 'Expected start <= end <= string length' unless finish.between?(start, text.length)

    text[start...finish]
  end

  def self.parse_number(text)
    typed(text, String)
    return text.to_i if text.match?(/\A[+-]?\d+\z/)
    return false unless text.match?(/\A[+-]?\d+\.\d+\z/)

    number = text.to_f
    number.finite? ? number : false
  end
end
