require "attr_extras/params_builder"

class AttrExtras::AttrInitialize
  def initialize(klass, names, block)
    @klass = klass
    @names = names
    @block = block
  end

  attr_reader :klass, :names
  private :klass, :names

  def apply
    # The define_method block can't call our methods, so we need to make
    # things available via local variables.
    block = @block

    klass_params = AttrExtras::AttrInitialize::ParamsBuilder.new(names)

    validate_arity = method(:validate_arity)
    validate_args = method(:validate_args)

    klass.send(:define_method, :initialize) do |*values|
      hash_values = (values[(klass_params.positional_args.length)..-1] || []).reduce(:merge) || {}

      validate_arity.call(values.length, self.class)
      validate_args.call(values, klass_params)

      klass_params.default_values.each do |name, default_value|
        instance_variable_set("@#{name}", default_value.dup)
      end

      klass_params.positional_args.zip(values).each do |name, value|
        instance_variable_set("@#{name}", value)
      end

      hash_values.each do |name, value|
        instance_variable_set("@#{name}", value)
      end

      if block
        instance_eval(&block)
      end
    end
  end

  private

  def validate_arity(provided_arity, klass)
    arity_without_hashes = names.count { |name| not name.is_a?(Array) }
    arity_with_hashes    = names.length

    unless (arity_without_hashes..arity_with_hashes).include?(provided_arity)
      arity_range = [ arity_without_hashes, arity_with_hashes ].uniq.join("..")
      raise ArgumentError, "wrong number of arguments (#{provided_arity} for #{arity_range}) for #{klass.name} initializer"
    end
  end

  def validate_args(values, klass_params)
    hash_values = values[(klass_params.positional_args.length)..-1].reduce(:merge) || {}
    unknown_keys = hash_values.keys - klass_params.hash_args_names

    if unknown_keys.any?
      raise ArgumentError, "Got unknown keys: #{unknown_keys.inspect}; allowed keys: #{klass_params.hash_args_names.inspect}"
    end

    missing_args = klass_params.hash_args_required - klass_params.default_values.keys - hash_values.keys
    if missing_args.any?
      raise KeyError, "Missing required keys: #{missing_args.inspect}"
    end
  end
end
