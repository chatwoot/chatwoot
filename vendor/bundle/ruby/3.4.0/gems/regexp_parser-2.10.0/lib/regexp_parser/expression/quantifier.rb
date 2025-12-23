module Regexp::Expression
  # TODO: in v3.0.0, maybe put Shared back into Base, and inherit from Base and
  # call super in #initialize, but raise in #quantifier= and #quantify,
  # or introduce an Expression::Quantifiable intermediate class.
  # Or actually allow chaining as a more concise but tricky solution than PR#69.
  class Quantifier
    include Regexp::Expression::Shared

    MODES = %i[greedy possessive reluctant]

    def initialize(*args)
      deprecated_old_init(*args) and return if args.count == 4 || args.count == 5

      init_from_token_and_options(*args)
      # TODO: remove in v3.0.0, stop removing parts of #token (?)
      self.token = token.to_s.sub(/_(greedy|possessive|reluctant)/, '').to_sym
    end

    def to_h
      {
        token: token,
        text:  text,
        mode:  mode,
        min:   min,
        max:   max,
      }
    end

    MODES.each do |mode|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{mode}?
          mode.equal?(:#{mode})
        end
      RUBY
    end
    alias :lazy? :reluctant?

    def min
      derived_data[:min]
    end

    def max
      derived_data[:max]
    end

    def mode
      derived_data[:mode]
    end

    private

    def deprecated_old_init(token, text, _min, _max, _mode = :greedy)
      warn "Calling `Expression::Base#quantify` or `#{self.class}.new` with 4+ arguments "\
           "is deprecated.\nIt will no longer be supported in regexp_parser v3.0.0.\n"\
           "Please pass a Regexp::Token instead, e.g. replace `token, text, min, max, mode` "\
           "with `::Regexp::Token.new(:quantifier, token, text)`. min, max, and mode "\
           "will be derived automatically.\n"\
           "Or do `exp.quantifier = #{self.class}.construct(token: token, text: str)`.\n"\
           "This is consistent with how Expression::Base instances are created. "
      @token = token
      @text  = text
    end

    def derived_data
      @derived_data ||= begin
        min, max =
          case text[0]
          when '?'; [0, 1]
          when '*'; [0, -1]
          when '+'; [1, -1]
          else
            int_min = text[/\{(\d*)/, 1]
            int_max = text[/,?(\d*)\}/, 1]
            [int_min.to_i, (int_max.empty? ? -1 : int_max.to_i)]
          end

        mod = text[/.([?+])/, 1]
        mode = (mod == '?' && :reluctant) || (mod == '+' && :possessive) || :greedy

        { min: min, max: max, mode: mode }
      end
    end
  end
end
