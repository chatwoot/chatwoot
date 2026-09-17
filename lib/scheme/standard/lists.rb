module Scheme::StandardLists
  private

  def lists
    predicate('null?') { |value| value.equal?(Scheme::EMPTY) }
    predicate('pair?') { |value| value.is_a?(Scheme::Pair) }
    predicate('list?') do |value|
      Scheme.to_a(value)
      true
    rescue Scheme::Error
      false
    end
    register('cons', 2) { |a, b| Scheme::Pair.new(a, b) }
    register('car', 1) { |value| check(value, Scheme::Pair).car }
    register('cdr', 1) { |value| check(value, Scheme::Pair).cdr }
    %w[car cdr].each do |part|
      register("set-#{part}!", 2) do |pair, value|
        mutable(check(pair, Scheme::Pair)).public_send("#{part}=", value)
        Scheme::UNSPECIFIED
      end
    end
    (2..4).each do |size|
      %w[a d].repeated_permutation(size) do |path|
        register("c#{path.join}r", 1) do |pair|
          path.reverse.reduce(pair) { |value, part| check(value, Scheme::Pair).public_send(part == 'a' ? :car : :cdr) }
        end
      end
    end
    register('list', 0, nil) { |*items| Scheme.list(items) }
    register('make-list', 1, 2) { |size, fill = Scheme::UNSPECIFIED| Scheme.list(Array.new(length(size), fill)) }
    register('length', 1) { |value| Scheme.to_a(value).length }
    register('reverse', 1) { |value| Scheme.list(Scheme.to_a(value).reverse) }
    register('append', 0, nil) do |*lists|
      lists.empty? ? Scheme::EMPTY : lists[0...-1].reverse.reduce(lists.last) { |tail, list| Scheme.list(Scheme.to_a(list), tail) }
    end
    register('list-tail', 2) { |list, offset| list_tail(list, offset) }
    register('list-ref', 2) { |list, offset| check(list_tail(list, offset), Scheme::Pair).car }
    register('list-set!', 3) do |list, offset, value|
      mutable(check(list_tail(list, offset), Scheme::Pair)).car = value
      Scheme::UNSPECIFIED
    end
    register('list-copy', 1) do |list|
      items = []
      seen = {}.compare_by_identity
      while list.is_a?(Scheme::Pair)
        raise Scheme::Error, 'cannot copy a cyclic list' if seen[list]

        seen[list] = true
        items << list.car
        list = list.cdr
      end
      Scheme.list(items, list)
    end
    membership
    iteration('map', collect: true)
    iteration('for-each', collect: false)
  end

  def list_tail(list, offset)
    length(offset).times { list = check(list, Scheme::Pair).cdr }
    list
  end

  def membership
    { 'memq' => :'eq?', 'memv' => :'eqv?', 'member' => :'equal?', 'assq' => :'eq?', 'assv' => :'eqv?', 'assoc' => :'equal?' }.each do |name, equality|
      maximum = %w[member assoc].include?(name) ? 3 : 2
      comparator = @runtime.environment.cell(equality)
      @runtime.control(name, min: 2, max: maximum) do |item, list, *optional, continuation|
        procedure = optional.first || comparator.value
        Scheme.to_a(list)
        member_step(item, list, procedure, name.start_with?('ass'), continuation)
      end
    end
  end

  def member_step(item, list, comparator, association, continuation)
    return @runtime.deliver(continuation, false) if list.equal?(Scheme::EMPTY)

    entry = association ? check(list.car, Scheme::Pair).car : list.car
    @runtime.invoke(comparator, [item, entry], lambda { |found|
      if @runtime.single(found) == false
        member_step(item, list.cdr, comparator, association, continuation)
      else
        @runtime.deliver(continuation, association ? list.car : list)
      end
    })
  end

  def iteration(name, collect:, kind: :list)
    @runtime.control(name, min: 2, max: nil) do |procedure, *collections, continuation|
      arrays = collections.map do |value|
        case kind
        when :list then Scheme.to_a(value)
        when :vector then check(value, Scheme::Vector).items.dup
        when :string then check(value, String).chars.map { |char| Scheme::Character.new(char) }
        end
      end
      finish = lambda do |values|
        result = if !collect
                   Scheme::UNSPECIFIED
                 elsif kind == :vector
                   Scheme::Vector.new(values)
                 elsif kind == :string
                   values.map { |value| check(value, Scheme::Character).value }.join
                 else
                   Scheme.list(values)
                 end
        @runtime.deliver(continuation, result)
      end
      iterate(procedure, arrays, 0, Scheme::EMPTY, collect, finish)
    end
  end

  def iterate(procedure, arrays, offset, accumulated, collect, continuation)
    return @runtime.deliver(continuation, Scheme.to_a(accumulated).reverse) if arrays.any? { |array| offset >= array.length }

    @runtime.invoke(procedure, arrays.map { |array| array[offset] }, lambda { |value|
      result = collect ? Scheme::Pair.new(@runtime.single(value), accumulated) : accumulated
      iterate(procedure, arrays, offset + 1, result, collect, continuation)
    })
  end
end
