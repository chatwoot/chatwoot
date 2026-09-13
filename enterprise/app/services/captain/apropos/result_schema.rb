class Captain::Apropos::ResultSchema
  MAX_DEPTH = 4
  MAX_FIELDS = 64
  MAX_OBJECT_FIELDS = 12
  MAX_SCHEMA_BYTES = 16_000
  MAX_RESULT_BYTES = 64_000
  MAX_ARRAY_ITEMS = 200
  TYPES = %w[string boolean integer number].freeze
  DESCRIPTION = 'Fields: string, boolean, integer, number; TYPE_list for primitive arrays; a list of strings for an enum; ' \
                'a hash for a nested object; a one-element list containing a hash for an array of objects. ' \
                'Example: (hash "needs" "string_list" "category" (list "billing" "technical")). ' \
                '(list "string") is an enum allowing only the literal "string", NOT an array of strings. Use "string_list" for that. ' \
                'All fields required. At most 4 nesting levels, 12 fields/object, 64 fields total, 200 items/array.'.freeze

  def self.build(fields)
    raise Captain::Apropos::Error, 'Result schema exceeds 16000 bytes' if JSON.generate(fields).bytesize > MAX_SCHEMA_BYTES

    new.object_schema(fields, '$', 0)
  end

  def initialize
    @field_count = 0
  end

  def object_schema(fields, path, depth)
    check_depth!(depth, path)
    unless fields.is_a?(Hash) && fields.size.between?(1, MAX_OBJECT_FIELDS)
      raise Captain::Apropos::Error, "#{path}: result object must declare 1 to #{MAX_OBJECT_FIELDS} fields"
    end

    @field_count += fields.size
    raise Captain::Apropos::Error, "#{path}: result schema exceeds #{MAX_FIELDS} fields" if @field_count > MAX_FIELDS

    properties = fields.to_h do |name, type|
      raise Captain::Apropos::Error, "#{path}: use snake_case string field names" unless name.is_a?(String) && name.match?(/\A[a-z][a-z0-9_]*\z/)

      [name, field_schema(type, "#{path}.#{name}", depth + 1)]
    end
    { 'type' => 'object', 'properties' => properties, 'required' => properties.keys, 'additionalProperties' => false }
  end

  private

  def field_schema(type, path, depth)
    check_depth!(depth, path)
    case type
    when Hash then object_schema(type, path, depth)
    when Array then list_schema(type, path, depth)
    when String then primitive_schema(type, path)
    else raise Captain::Apropos::Error, "#{path}: unsupported result type. #{DESCRIPTION}"
    end
  end

  def list_schema(type, path, depth)
    return array_schema(object_schema(type.first, "#{path}[]", depth + 1)) if type.size == 1 && type.first.is_a?(Hash)
    unless type.any? && type.all?(String) && type.uniq == type
      raise Captain::Apropos::Error, "#{path}: use unique strings for an enum, or one object schema for an array of objects"
    end

    { 'type' => 'string', 'enum' => type }
  end

  def primitive_schema(type, path)
    return { 'type' => type } if TYPES.include?(type)

    item_type = type.delete_suffix('_list')
    return array_schema({ 'type' => item_type }) if type.end_with?('_list') && TYPES.include?(item_type)

    raise Captain::Apropos::Error, "#{path}: unsupported result type #{type.inspect}. #{DESCRIPTION}"
  end

  def array_schema(items)
    { 'type' => 'array', 'items' => items, 'maxItems' => MAX_ARRAY_ITEMS }
  end

  def check_depth!(depth, path)
    raise Captain::Apropos::Error, "#{path}: result schema exceeds #{MAX_DEPTH} nesting levels" if depth > MAX_DEPTH
  end
end
