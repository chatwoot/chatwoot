module SafeYAML
  class Transform
    class ToSymbol
      def transform?(value, options=SafeYAML::OPTIONS)
        if options[:deserialize_symbols] && value =~ /\A:./
          if value =~ /\A:(["'])(.*)\1\Z/
            return true, $2.sub(/^:/, "").to_sym
          else
            return true, value.sub(/^:/, "").to_sym
          end
        end

        return false
      end
    end
  end
end
