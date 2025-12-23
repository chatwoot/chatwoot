class Regexp::MatchLength
  include Enumerable

  def self.of(obj)
    exp = obj.is_a?(Regexp::Expression::Base) ? obj : Regexp::Parser.parse(obj)
    exp.match_length
  end

  def initialize(exp, opts = {})
    self.exp_class = exp.class
    self.min_rep = exp.repetitions.min
    self.max_rep = exp.repetitions.max
    if (base = opts[:base])
      self.base_min = base
      self.base_max = base
      self.reify = ->{ '.' * base }
    else
      self.base_min = opts.fetch(:base_min)
      self.base_max = opts.fetch(:base_max)
      self.reify = opts.fetch(:reify)
    end
  end

  def each(opts = {})
    return enum_for(__method__, opts) unless block_given?
    limit = opts[:limit] || 1000
    yielded = 0
    (min..max).each do |num|
      next unless include?(num)
      yield(num)
      break if (yielded += 1) >= limit
    end
  end

  def endless_each
    return enum_for(__method__) unless block_given?
    (min..max).each { |num| yield(num) if include?(num) }
  end

  def include?(length)
    test_regexp.match?('X' * length)
  end

  def fixed?
    min == max
  end

  def min
    min_rep * base_min
  end

  def max
    max_rep * base_max
  end

  def minmax
    [min, max]
  end

  def inspect
    type = exp_class.name.sub('Regexp::Expression::', '')
    "#<#{self.class}<#{type}> min=#{min} max=#{max}>"
  end

  def to_re
    /(?:#{reify.call}){#{min_rep},#{max_rep unless max_rep == Float::INFINITY}}/
  end

  private

  attr_accessor :base_min, :base_max, :min_rep, :max_rep, :exp_class, :reify

  if Regexp.method_defined?(:match?) # ruby >= 2.4
    def test_regexp
      @test_regexp ||= /^#{to_re}$/
    end
  else
    def test_regexp
      @test_regexp ||= /^#{to_re}$/.tap { |r| def r.match?(s); !!match(s) end }
    end
  end
end

module Regexp::Expression
  MatchLength = Regexp::MatchLength

  [
    CharacterSet,
    CharacterSet::Intersection,
    CharacterSet::IntersectedSequence,
    CharacterSet::Range,
    CharacterType::Base,
    EscapeSequence::Base,
    PosixClass,
    UnicodeProperty::Base,
  ].each do |klass|
    klass.class_eval <<-RUBY, __FILE__, __LINE__ + 1
      def match_length
        MatchLength.new(self, base: 1)
      end
    RUBY
  end

  class Literal
    def match_length
      MatchLength.new(self, base: text.length)
    end
  end

  class Subexpression
    def match_length
      MatchLength.new(self,
                       base_min: map { |exp| exp.match_length.min }.inject(0, :+),
                       base_max: map { |exp| exp.match_length.max }.inject(0, :+),
                       reify: ->{ map { |exp| exp.match_length.to_re }.join })
    end

    def inner_match_length
      dummy = Regexp::Expression::Root.construct
      dummy.expressions = expressions.map(&:clone)
      dummy.quantifier = quantifier && quantifier.clone
      dummy.match_length
    end
  end

  [
    Alternation,
    Conditional::Expression,
  ].each do |klass|
    klass.class_eval <<-RUBY, __FILE__, __LINE__ + 1
      def match_length
        MatchLength.new(self,
                         base_min: map { |exp| exp.match_length.min }.min,
                         base_max: map { |exp| exp.match_length.max }.max,
                         reify: ->{ map { |exp| exp.match_length.to_re }.join('|') })
      end
    RUBY
  end

  [
    Anchor::Base,
    Assertion::Base,
    Conditional::Condition,
    FreeSpace,
    Keep::Mark,
  ].each do |klass|
    klass.class_eval <<-RUBY, __FILE__, __LINE__ + 1
      def match_length
        MatchLength.new(self, base: 0)
      end
    RUBY
  end

  class Backreference::Base
    def match_length
      if referenced_expression.nil?
        raise ArgumentError, 'Missing referenced_expression - not parsed?'
      end
      referenced_expression.unquantified_clone.match_length
    end
  end

  class EscapeSequence::CodepointList
    def match_length
      MatchLength.new(self, base: codepoints.count)
    end
  end

  # Special case. Absence group can match 0.. chars, irrespective of content.
  # TODO: in theory, they *can* exclude match lengths with `.`: `(?~.{3})`
  class Group::Absence
    def match_length
      MatchLength.new(self, base_min: 0, base_max: Float::INFINITY, reify: ->{ '.*' })
    end
  end
end
