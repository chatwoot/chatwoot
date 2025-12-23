# frozen_string_literal: true

module RuboCop
  # ...
  module AST
    # Responsible for compatibility with main gem
    # @api private
    module RuboCopCompatibility
      INCOMPATIBLE_COPS = {
        '0.89.0' => 'Layout/LineLength',
        '0.92.0' => 'Style/MixinUsage'
      }.freeze
      def rubocop_loaded
        loaded = Gem::Version.new(RuboCop::Version::STRING)
        incompatible = INCOMPATIBLE_COPS.select do |k, _v|
          loaded < Gem::Version.new(k)
        end.values
        return if incompatible.empty?

        warn <<~WARNING
          *** WARNING – Incompatible versions of `rubocop` and `rubocop-ast`
          You may encounter issues with the following \
          Cop#{'s' if incompatible.size > 1}: #{incompatible.join(', ')}
          Please upgrade rubocop to at least v#{INCOMPATIBLE_COPS.keys.last}
        WARNING
      end
    end

    extend RuboCopCompatibility
  end
end
