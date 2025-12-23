# frozen_string_literal: true

# Prepares the target name of a parameter or an option.
#
# Unlike source, the target must satisfy requirements for Ruby variable names.
# It also shouldn't be in conflict with names used by the gem.
#
module Dry
  module Initializer
    module Dispatchers
      module PrepareTarget
        extend self

        # List of variable names reserved by the gem
        RESERVED = %i[
          __dry_initializer_options__
          __dry_initializer_config__
          __dry_initializer_value__
          __dry_initializer_definition__
          __dry_initializer_initializer__
        ].freeze

        def call(source:, target: nil, as: nil, **options)
          target ||= as || source
          target = target.to_s.to_sym.downcase

          check_ruby_name!(target)
          check_reserved_names!(target)

          {source:, target:, **options}
        end

        private

        def check_ruby_name!(target)
          return if target[/\A[[:alpha:]_][[:alnum:]_]*\??\z/u]

          raise ArgumentError,
                "The name `#{target}` is not allowed for Ruby methods"
        end

        def check_reserved_names!(target)
          return unless RESERVED.include?(target)

          raise ArgumentError,
                "The method name `#{target}` is reserved by the dry-initializer gem"
        end
      end
    end
  end
end
