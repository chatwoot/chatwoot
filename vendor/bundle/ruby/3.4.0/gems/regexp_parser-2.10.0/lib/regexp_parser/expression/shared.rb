module Regexp::Expression
  module Shared
    module ClassMethods; end # filled in ./methods/*.rb

    def self.included(mod)
      mod.class_eval do
        extend Shared::ClassMethods

        attr_accessor :type, :token, :text, :ts, :te,
                      :level, :set_level, :conditional_level,
                      :options, :parent,
                      :custom_to_s_handling, :pre_quantifier_decorations

        attr_reader   :nesting_level, :quantifier
      end
    end

    def init_from_token_and_options(token, options = {})
      self.type              = token.type
      self.token             = token.token
      self.text              = token.text
      self.ts                = token.ts
      self.te                = token.te
      self.level             = token.level
      self.set_level         = token.set_level
      self.conditional_level = token.conditional_level
      self.nesting_level     = 0
      self.options           = options || {}
    end
    private :init_from_token_and_options

    def initialize_copy(orig)
      self.text       = orig.text.dup         if orig.text
      self.options    = orig.options.dup      if orig.options
      self.quantifier = orig.quantifier.clone if orig.quantifier
      self.parent     = nil # updated by Subexpression#initialize_copy
      if orig.pre_quantifier_decorations
        self.pre_quantifier_decorations = orig.pre_quantifier_decorations.map(&:dup)
      end
      super
    end

    def starts_at
      ts
    end

    def ends_at(include_quantifier = true)
      ts + (include_quantifier ? full_length : base_length)
    end

    def base_length
      to_s(:base).length
    end

    def full_length
      to_s(:original).length
    end

    # #to_s reproduces the original source, as an unparser would.
    #
    # It takes an optional format argument.
    #
    # Example:
    #
    # lit = Regexp::Parser.parse(/a +/x)[0]
    #
    # lit.to_s            # => 'a+'  # default; with quantifier
    # lit.to_s(:full)     # => 'a+'  # default; with quantifier
    # lit.to_s(:base)     # => 'a'   # without quantifier
    # lit.to_s(:original) # => 'a +' # with quantifier AND intermittent decorations
    #
    def to_s(format = :full)
      base = parts.each_with_object(''.dup) do |part, buff|
        if part.instance_of?(String)
          buff << part
        elsif !part.custom_to_s_handling
          buff << part.to_s(:original)
        end
      end
      "#{base}#{pre_quantifier_decoration(format)}#{quantifier_affix(format)}"
    end
    alias :to_str :to_s

    def pre_quantifier_decoration(expression_format = :original)
      pre_quantifier_decorations.to_a.join if expression_format == :original
    end

    def quantifier_affix(expression_format = :full)
      quantifier.to_s if quantified? && expression_format != :base
    end

    def offset
      [starts_at, full_length]
    end

    def coded_offset
      '@%d+%d' % offset
    end

    def nesting_level=(lvl)
      @nesting_level = lvl
      quantifier && quantifier.nesting_level = lvl
      terminal? || each { |subexp| subexp.nesting_level = lvl + 1 }
    end

    def quantifier=(qtf)
      @quantifier = qtf
      @repetitions = nil # clear memoized value
    end
  end
end
