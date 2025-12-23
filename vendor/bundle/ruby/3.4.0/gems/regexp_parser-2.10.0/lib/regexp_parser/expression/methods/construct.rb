module Regexp::Expression
  module Shared
    module ClassMethods
      # Convenience method to init a valid Expression without a Regexp::Token
      def construct(params = {})
        attrs = construct_defaults.merge(params)
        options = attrs.delete(:options)
        token_args = Regexp::TOKEN_KEYS.map { |k| attrs.delete(k) }
        token = Regexp::Token.new(*token_args)
        raise ArgumentError, "unsupported attribute(s): #{attrs}" if attrs.any?

        new(token, options)
      end

      def construct_defaults
        if self == Root
          { type: :expression, token: :root, ts: 0 }
        elsif self < Sequence
          { type: :expression, token: :sequence }
        else
          { type: token_class::Type }
        end.merge(level: 0, set_level: 0, conditional_level: 0, text: '')
      end

      def token_class
        if self == Root || self < Sequence
          nil # no token class because these objects are Parser-generated
        # TODO: synch exp class, token class & type names for this in v3.0.0
        elsif self == CharacterType::Any
          Regexp::Syntax::Token::Meta
        else
          Regexp::Syntax::Token.const_get(name.split('::')[2])
        end
      end
    end

    def token_class
      self.class.token_class
    end
  end
end
