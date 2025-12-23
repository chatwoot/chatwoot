# Encapsulates the management and checking of ignored exceptions. Allows using
# string matches on the class name, or arbitrary matching with a callback
module ScoutApm
  module ErrorService
    class IgnoredExceptions
      attr_reader :ignored_exceptions
      attr_reader :blocks

      def initialize(context, from_config)
        @context = context
        @ignored_exceptions = Array(from_config).map{ |e| normalize_as_klass(e) }
        @blocks = []
      end

      # Add a single ignored exception by class name
      def add(klass_or_str)
        @ignored_exceptions << normalize_as_klass(klass_or_str)
      end

      # Add a callback block that will be called on every error. If it returns
      # Signature of blocks:  ->(exception object): truthy or falsy value
      def add_callback(&block)
        @blocks << block
      end

      def ignored?(exception_object)
        klass = normalize_as_klass(exception_object)

        # Check if we ignored this error by name (typical way to ignore)
        if ignored_exceptions.any? { |ignored| klass.ancestors.include?(ignored) }
          return true
        end

        # For each block, see if it says we should ignore this error
        blocks.each do |b|
          if b.call(exception_object)
            return true
          end
        end

        false
      end

      private

      def normalize_as_klass(klass_or_str)
        if Module === klass_or_str
          return klass_or_str
        end

        if klass_or_str.is_a?(Exception)
          return klass_or_str.class
        end

        if String === klass_or_str
          maybe = ScoutApm::Utils::KlassHelper.lookup(klass_or_str)
          if Module === maybe
            return maybe
          end
        end

        klass_or_str
      end
    end
  end
end
