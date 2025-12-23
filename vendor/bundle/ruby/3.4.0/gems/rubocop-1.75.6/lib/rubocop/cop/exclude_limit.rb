# frozen_string_literal: true

module RuboCop
  # Allows specified configuration options to have an exclude limit
  # ie. a maximum value tracked that it can be used by `--auto-gen-config`.
  module ExcludeLimit
    # Sets up a configuration option to have an exclude limit tracked.
    # The parameter name given is transformed into a method name (eg. `Max`
    # becomes `self.max=` and `MinDigits` becomes `self.min_digits=`).
    def exclude_limit(parameter_name, method_name: transform(parameter_name))
      define_method(:"#{method_name}=") do |value|
        cfg = config_to_allow_offenses
        cfg[:exclude_limit] ||= {}
        current_max = cfg[:exclude_limit][parameter_name]
        value = [current_max, value].max if current_max
        cfg[:exclude_limit][parameter_name] = value
      end
    end

    private

    def transform(parameter_name)
      parameter_name.gsub(/(?<!\A)(?=[A-Z])/, '_').downcase
    end
  end
end
