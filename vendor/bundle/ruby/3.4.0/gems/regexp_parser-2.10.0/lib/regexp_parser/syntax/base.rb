module Regexp::Syntax
  class NotImplementedError < Regexp::Syntax::SyntaxError
    def initialize(syntax, type, token)
      super "#{syntax} does not implement: [#{type}:#{token}]"
    end
  end

  # A lookup map of supported types and tokens in a given syntax
  class Base
    include Regexp::Syntax::Token

    class << self
      attr_accessor :features

      # automatically inherit features through the syntax class hierarchy
      def inherited(subclass)
        super
        subclass.features = features.to_h.map { |k, v| [k, v.dup] }.to_h
      end

      def implements(type, tokens)
        (features[type] ||= []).concat(tokens)
        added_features[type] = tokens
      end

      def excludes(type, tokens)
        tokens.each { |tok| features[type].delete(tok) }
        removed_features[type] = tokens
      end

      def implements?(type, token)
        implementations(type).include?(token)
      end
      alias :check? :implements?

      def implementations(type)
        features[type] || []
      end

      def implements!(type, token)
        raise NotImplementedError.new(self, type, token) unless
          implements?(type, token)
      end
      alias :check! :implements!

      def added_features
        @added_features ||= {}
      end

      def removed_features
        @removed_features ||= {}
      end

      def normalize(type, token)
        case type
        when :group
          normalize_group(type, token)
        when :backref
          normalize_backref(type, token)
        else
          [type, token]
        end
      end

      def normalize_group(type, token)
        case token
        when :named_ab, :named_sq
          %i[group named]
        else
          [type, token]
        end
      end

      def normalize_backref(type, token)
        case token
        when :name_ref_ab, :name_ref_sq
          %i[backref name_ref]
        when :name_call_ab, :name_call_sq
          %i[backref name_call]
        when :name_recursion_ref_ab, :name_recursion_ref_sq
          %i[backref name_recursion_ref]
        when :number_ref_ab, :number_ref_sq
          %i[backref number_ref]
        when :number_call_ab, :number_call_sq
          %i[backref number_call]
        when :number_rel_ref_ab, :number_rel_ref_sq
          %i[backref number_rel_ref]
        when :number_rel_call_ab, :number_rel_call_sq
          %i[backref number_rel_call]
        when :number_recursion_ref_ab, :number_recursion_ref_sq
          %i[backref number_recursion_ref]
        else
          [type, token]
        end
      end
    end

    # TODO: drop this backwards compatibility code in v3.0.0, do `private :new`
    def initialize
      warn 'Using instances of Regexp::Parser::Syntax is deprecated ' \
           "and will no longer be supported in v3.0.0."
    end

    def method_missing(name, *args)
      if self.class.respond_to?(name)
        warn 'Using instances of Regexp::Parser::Syntax is deprecated ' \
             "and will no longer be supported in v3.0.0. Please call "\
             "methods on the class directly, e.g.: #{self.class}.#{name}"
        self.class.send(name, *args)
      else
        super
      end
    end

    def respond_to_missing?(name, include_private = false)
      self.class.respond_to?(name) || super
    end
    # end of backwards compatibility code
  end
end
