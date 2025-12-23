module AttrExtras
  class AttrInitialize
    class ParamsBuilder
      REQUIRED_SIGN = "!".freeze

      def initialize(names)
        @names = names
      end

      attr_reader :names
      private :names

      def positional_args
        @positional_args ||= names.take_while { |name| !name.is_a?(Array) }
      end

      def hash_args
        @hash_args ||= (names - positional_args).flatten.flat_map { |name|
          name.is_a?(Hash) ? name.keys : name
        }
      end

      def hash_args_names
        @hash_args_names ||= hash_args.map { |name| remove_required_sign(name) }
      end

      def hash_args_required
        @hash_args_required ||= hash_args.select { |name| name.to_s.end_with?(REQUIRED_SIGN) }
          .map { |name| remove_required_sign(name) }
      end

      def default_values
        @default_values ||= begin
          default_values_hash = names.flatten.select { |name| name.is_a?(Hash) }.reduce(:merge) || {}

          default_values_hash.map { |name, value|
            [ remove_required_sign(name), value ]
          }.to_h
        end
      end

      private

      def remove_required_sign(name)
        name.to_s.sub(/#{REQUIRED_SIGN}\z/, "").to_sym
      end
    end
  end
end
