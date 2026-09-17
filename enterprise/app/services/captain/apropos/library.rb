class Captain::Apropos::Library
  MAX_FUNCTIONS = 100
  MAX_DEFINITION_BYTES = 16_384
  MAX_DESCRIPTION_LENGTH = 500

  def initialize(account:, user:, scheme:)
    @account = account
    @user = user
    @scheme = scheme
    @entries = {}
    Captain::Apropos::Access.check!(account, user)
    records.find_each { |record| install(record) }
  end

  def entries
    @entries.transform_values { |entry| entry.except(:binding) }
  end

  def describe(name)
    @entries.fetch(name)
  end

  def save(name, description, expression)
    Captain::Apropos::Access.check!(@account, @user)
    expression = Captain::Apropos::SchemeValues.from_ruby(expression)
    validate!(name, description, expression)
    record = @user.with_lock do
      function = records.find_or_initialize_by(name: name)
      raise Captain::Apropos::Error, 'Function library is full (100 functions)' if function.new_record? && records.count >= MAX_FUNCTIONS

      function.update!(description: description, definition: Captain::Apropos::Codec.dump(expression))
      function
    end
    install(record)
    entries.fetch(name)
  end

  private

  def records
    Captain::AproposFunction.where(account_id: @account.id, user_id: @user.id)
  end

  def validate!(name, description, expression)
    validate_name!(name)
    unless description.is_a?(String) && description.strip.length.between?(1, MAX_DESCRIPTION_LENGTH)
      raise Captain::Apropos::Error, 'Function description must contain 1 to 500 characters'
    end
    if JSON.generate(Captain::Apropos::Codec.dump(expression)).bytesize > MAX_DEFINITION_BYTES
      raise Captain::Apropos::Error, 'Function definition exceeds 16 KB'
    end

    @scheme.library_function(expression)
  end

  def validate_name!(name)
    unless name.is_a?(String) && name.match?(/\A[a-z][a-z0-9-]{0,63}\z/)
      raise Captain::Apropos::Error, 'Function name must be 1 to 64 lowercase letters, digits, or hyphens, starting with a letter'
    end

    catalog_entries = [Captain::Apropos::Catalog::FUNCTIONS, Captain::Apropos::Catalog::ENTITIES, Captain::Apropos::Catalog::ACTIONS]
    raise Captain::Apropos::Error, 'Cannot replace a built-in catalog entry' if catalog_entries.any? { |entries| entries.key?(name) }
    raise Captain::Apropos::Error, 'Cannot replace a standard Scheme binding' if @scheme.builtins.cell(name.to_sym)
  end

  def install(record)
    function = @scheme.library_function(Captain::Apropos::Codec.load(record.definition))
    @scheme.install_library(record.name, function)
    @entries[record.name] = {
      signature: ::Scheme.write(::Scheme::Pair.new(record.name.to_sym, function.parameters)), description: record.description,
      binding: { type: 'closure', source: ::Scheme.write(::Scheme.list([:lambda, function.parameters, *function.body])) }
    }
  end
end
