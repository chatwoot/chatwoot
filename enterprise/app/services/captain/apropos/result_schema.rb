class Captain::Apropos::ResultSchema
  def self.build(fields)
    raise Captain::Apropos::Error, 'Result schema must declare 1 to 12 fields' unless fields.is_a?(Hash) && fields.size.between?(1, 12)

    Class.new(RubyLLM::Schema).tap do |schema|
      fields.each do |name, type|
        raise Captain::Apropos::Error, 'Use snake_case field names' unless name.match?(/\A[a-z][a-z0-9_]*\z/)

        add_field(schema, name, type)
      end
    end
  end

  def self.add_field(schema, name, type)
    if type.is_a?(Array) && type.any? && type.all?(String)
      schema.string(name.to_sym, enum: type)
    elsif type == 'string_list'
      schema.array(name.to_sym, of: :string)
    elsif %w[string boolean integer].include?(type)
      schema.public_send(type, name.to_sym)
    else
      raise Captain::Apropos::Error, "Unsupported result type for #{name}"
    end
  end
end
