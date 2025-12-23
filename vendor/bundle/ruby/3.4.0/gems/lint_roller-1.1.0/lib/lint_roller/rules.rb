module LintRoller
  Rules = Struct.new(
    # Valid values: :path, :object, :error
    :type,
    # Only known value right now is :rubocop but nothing would stop rufo or
    # rubyfmt or prettier from adding support without a change to the gem
    :config_format,
    # If type is :path, String or Pathname. Otherwise, whatever :object type
    # makes sense given :config_format (e.g. for RuboCop, a Hash loaded from a
    # YAML file; note that providing a hash will prevent the use of RuboCop features
    # like `inherit_from' and `require'!)
    :value,
    # If something went wrong an Error for the runner to deal with appropriately
    :error,
    keyword_init: true
  )
end
