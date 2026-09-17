module Scheme
  class Error < StandardError; end
  class ReadError < Error; end
  class LimitError < Error; end

  EMPTY = Object.new.freeze
  UNSPECIFIED = Object.new.freeze
  UNINITIALIZED = Object.new.freeze

  class Pair
    attr_accessor :car, :cdr

    def initialize(car, cdr = EMPTY)
      @car = car
      @cdr = cdr
    end
  end

  class Character
    attr_reader :value

    def initialize(value)
      raise Error, 'expected a single character' unless value.is_a?(String) && value.length == 1

      @value = value.freeze
      freeze
    end

    def ==(other)
      other.is_a?(Character) && value == other.value
    end
  end

  class Vector
    attr_reader :items

    def initialize(items)
      @items = items
    end
  end

  class Bytevector
    attr_reader :items

    def initialize(items)
      raise Error, 'bytevector elements must be integers between 0 and 255' unless items.all? { |item| item.is_a?(Integer) && item.between?(0, 255) }

      @items = items
    end
  end

  MultipleValues = Struct.new(:items)

  def self.list(items, tail = EMPTY)
    items.reverse_each.reduce(tail) { |rest, item| Pair.new(item, rest) }
  end

  def self.to_a(value)
    items = []
    seen = {}.compare_by_identity
    while value.is_a?(Pair)
      raise Error, 'expected a proper list, found a cyclic list' if seen[value]

      seen[value] = true
      items << value.car
      value = value.cdr
    end
    raise Error, 'expected a proper list' unless value.equal?(EMPTY)

    items
  end

  def self.literal(value, seen = {}.compare_by_identity)
    pending = [value]
    until pending.empty?
      item = pending.pop
      next if seen[item]

      seen[item] = true
      case item
      when Pair then pending.push(item.car, item.cdr)
      when Vector, Bytevector
        pending.concat(item.items)
        item.items.freeze
      end
      item.freeze
    end
    value
  end

  def self.eqv?(left, right)
    return left == right if left.is_a?(Character) && right.is_a?(Character)
    return Numbers.exact?(left) == Numbers.exact?(right) && left == right if left.is_a?(Numeric) && right.is_a?(Numeric)

    left.equal?(right)
  end

  def self.equal?(left, right, seen = {})
    pending = [[left, right]]
    until pending.empty?
      a, b = pending.pop
      next if eqv?(a, b)
      return false unless a.class == b.class

      key = [a.object_id, b.object_id]
      next if seen[key]

      seen[key] = true
      case a
      when Pair then pending.push([a.car, b.car], [a.cdr, b.cdr])
      when Vector, Bytevector
        return false unless a.items.length == b.items.length

        pending.concat(a.items.zip(b.items))
      when String
        return false unless a == b
      else return false
      end
    end
    true
  end
end
