# https://github.com/rails/rails/blob/352865d0f835c24daa9a2e9863dcc9dde9e5371a/activesupport/lib/active_support/inflector/methods.rb#L270

module Sidekiq
  module Cron
    module Support
      def self.constantize(camel_cased_word)
        names = camel_cased_word.split("::".freeze)

        # Trigger a built-in NameError exception including the ill-formed constant in the message.
        Object.const_get(camel_cased_word) if names.empty?

        # Remove the first blank element in case of '::ClassName' notation.
        names.shift if names.size > 1 && names.first.empty?

        names.inject(Object) do |constant, name|
          if constant == Object
            constant.const_get(name)
          else
            candidate = constant.const_get(name)
            next candidate if constant.const_defined?(name, false)
            next candidate unless Object.const_defined?(name)

            # Go down the ancestors to check if it is owned directly. The check
            # stops when we reach Object or the end of ancestors tree.
            constant = constant.ancestors.inject(constant) do |const, ancestor|
              break const    if ancestor == Object
              break ancestor if ancestor.const_defined?(name, false)
              const
            end

            constant.const_get(name, false)
          end
        end
      end

      def self.load_yaml(src)
        if Psych::VERSION > "4.0"
          YAML.safe_load(src, permitted_classes: [Symbol], aliases: true)
        else
          YAML.load(src)
        end
      end
    end
  end
end
