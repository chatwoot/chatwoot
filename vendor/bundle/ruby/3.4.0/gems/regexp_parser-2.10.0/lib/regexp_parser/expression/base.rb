module Regexp::Expression
  class Base
    include Regexp::Expression::Shared

    def initialize(token, options = {})
      init_from_token_and_options(token, options)
    end

    def to_re(format = :full)
      if set_level > 0
        warn "Calling #to_re on character set members is deprecated - "\
             "their behavior might not be equivalent outside of the set."
      end
      ::Regexp.new(to_s(format))
    end

    def quantify(*args)
      self.quantifier = Quantifier.new(*args)
    end

    def unquantified_clone
      clone.tap { |exp| exp.quantifier = nil }
    end

    # Deprecated. Prefer `#repetitions` which has a more uniform interface.
    def quantity
      return [nil,nil] unless quantified?
      [quantifier.min, quantifier.max]
    end

    def repetitions
      @repetitions ||=
        if quantified?
          min = quantifier.min
          max = quantifier.max < 0 ? Float::INFINITY : quantifier.max
          range = min..max
          # fix Range#minmax on old Rubies - https://bugs.ruby-lang.org/issues/15807
          if RUBY_VERSION.to_f < 2.7
            range.define_singleton_method(:minmax) { [min, max] }
          end
          range
        else
          1..1
        end
    end

    def greedy?
      quantified? and quantifier.greedy?
    end

    def reluctant?
      quantified? and quantifier.reluctant?
    end
    alias :lazy? :reluctant?

    def possessive?
      quantified? and quantifier.possessive?
    end

    def to_h
      {
        type:              type,
        token:             token,
        text:              to_s(:base),
        starts_at:         ts,
        length:            full_length,
        level:             level,
        set_level:         set_level,
        conditional_level: conditional_level,
        options:           options,
        quantifier:        quantified? ? quantifier.to_h : nil,
      }
    end
    alias :attributes :to_h
  end
end
