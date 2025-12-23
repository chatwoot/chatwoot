# This is a module-class hybrid.
#
# Hashie's standard SymbolizeKeys is similar to the functionality we want.
# ... but not quite.  We need to support both String (for oauth2) and Symbol keys (for oauth).
# include Hashie::Extensions::Mash::SymbolizeKeys
module SnakyHash
  class Snake < Module
    def initialize(key_type: :string)
      super()
      @key_type = key_type
    end

    def included(base)
      conversions_module = SnakyModulizer.to_mod(@key_type)
      base.include(conversions_module)
    end

    module SnakyModulizer
      def self.to_mod(key_type)
        Module.new do
          # Converts a key to a symbol, or a string, depending on key_type,
          #   but only if it is able to be converted to a symbol,
          #   and after underscoring it.
          #
          # @api private
          # @param [<K>] key the key to attempt convert to a symbol
          # @return [Symbol, K]

          case key_type
          when :string then
            define_method(:convert_key) { |key| key.respond_to?(:to_sym) ? underscore_string(key.to_s) : key }
          when :symbol then
            define_method(:convert_key) { |key| key.respond_to?(:to_sym) ? underscore_string(key.to_s).to_sym : key }
          else
            raise ArgumentError, "SnakyHash: Unhandled key_type: #{key_type}"
          end

          # Unlike its parent Mash, a SnakyHash::Snake will convert other
          #   Hashie::Hash values to a SnakyHash::Snake when assigning
          #   instead of respecting the existing subclass
          define_method :convert_value do |val, duping = false| #:nodoc:
            case val
            when self.class
              val.dup
            when ::Hash
              val = val.dup if duping
              self.class.new(val)
            when ::Array
              val.collect { |e| convert_value(e) }
            else
              val
            end
          end

          # converts a camel_cased string to a underscore string
          # subs spaces with underscores, strips whitespace
          # Same way ActiveSupport does string.underscore
          define_method :underscore_string do |str|
            str.to_s.strip
               .tr(" ", "_")
               .gsub(/::/, "/")
               .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
               .gsub(/([a-z\d])([A-Z])/, '\1_\2')
               .tr("-", "_")
               .squeeze("_")
               .downcase
          end
        end
      end
    end
  end
end
