module Scheme::StandardSequences
  private

  def sequences
    characters
    strings
    vectors
  end

  def characters
    register('char->integer', 1) { |char| check(char, Scheme::Character).value.ord }
    register('integer->char', 1) { |code| Scheme::Character.new(check(code, Integer).chr(Encoding::UTF_8)) }
    { '=?' => :==, '<?' => :<, '>?' => :>, '<=?' => :<=, '>=?' => :>= }.each do |suffix, operator|
      register("char#{suffix}", 2, nil) do |*characters|
        characters.map { |char| check(char, Scheme::Character).value }.each_cons(2).all? { |a, b| a.public_send(operator, b) }
      end
    end
  end

  def strings
    register('string', 0, nil) { |*chars| chars.map { |char| check(char, Scheme::Character).value }.join }
    register('make-string', 1, 2) { |size, fill = Scheme::Character.new("\0")| check(fill, Scheme::Character).value * length(size) }
    register('string-length', 1) { |value| check(value, String).length }
    register('string-ref', 2) { |value, offset| Scheme::Character.new(check(value, String)[index(offset, value.length)]) }
    register('string-set!', 3) do |value, offset, char|
      mutable(check(value, String))[index(offset, value.length)] = check(char, Scheme::Character).value
      Scheme::UNSPECIFIED
    end
    register('string-append', 0, nil) { |*values| values.map { |value| check(value, String) }.join }
    register('string-copy', 1, 3) { |value, *bounds| slice(check(value, String), bounds).dup }
    register('substring', 3) { |value, start, finish| slice(check(value, String), [start, finish]).dup }
    register('string->list', 1, 3) do |value, *bounds|
      Scheme.list(slice(check(value, String), bounds).chars.map do |char|
        Scheme::Character.new(char)
      end)
    end
    register('list->string', 1) { |value| Scheme.to_a(value).map { |char| check(char, Scheme::Character).value }.join }
    register('string-fill!', 2, 4) do |value, char, *bounds|
      mutable(check(value, String))
      range = slice_range(value.length, bounds)
      value[range] = check(char, Scheme::Character).value * range.size
      Scheme::UNSPECIFIED
    end
    register('string-copy!', 3, 5) do |target, offset, source, *bounds|
      copy_into(mutable(check(target, String)), offset, slice(check(source, String), bounds))
      Scheme::UNSPECIFIED
    end
    { '=?' => :==, '<?' => :<, '>?' => :>, '<=?' => :<=, '>=?' => :>= }.each do |suffix, operator|
      register("string#{suffix}", 2, nil) do |*values|
        values.each { |value| check(value, String) }.each_cons(2).all? { |a, b| a.public_send(operator, b) }
      end
    end
    iteration('string-map', collect: true, kind: :string)
    iteration('string-for-each', collect: false, kind: :string)
  end

  def vectors
    { 'vector' => Scheme::Vector, 'bytevector' => Scheme::Bytevector }.each do |name, type|
      register(name, 0, nil) { |*items| type.new(items) }
      default_fill = name == 'bytevector' ? 0 : Scheme::UNSPECIFIED
      register("make-#{name}", 1, 2) { |size, fill = default_fill| type.new(Array.new(length(size), fill)) }
      register("#{name}-length", 1) { |value| check(value, type).items.length }
      register("#{name}#{name == 'bytevector' ? '-u8' : ''}-ref", 2) do |value, offset|
        check(value, type).items[index(offset, value.items.length)]
      end
      register("#{name}#{name == 'bytevector' ? '-u8' : ''}-set!", 3) do |value, offset, item|
        mutable(check(value, type))
        type.new([item]) if name == 'bytevector'
        value.items[index(offset, value.items.length)] = item
        Scheme::UNSPECIFIED
      end
      register("#{name}-copy", 1, 3) { |value, *bounds| type.new(slice(check(value, type).items, bounds)) }
      register("#{name}-copy!", 3, 5) do |target, offset, source, *bounds|
        copy_into(mutable(check(target, type)).items, offset, slice(check(source, type).items, bounds))
        Scheme::UNSPECIFIED
      end
      register("#{name}-append", 0, nil) { |*values| type.new(values.flat_map { |value| check(value, type).items }) }
    end
    register('vector->list', 1, 3) { |value, *bounds| Scheme.list(slice(check(value, Scheme::Vector).items, bounds)) }
    register('list->vector', 1) { |value| Scheme::Vector.new(Scheme.to_a(value)) }
    register('vector->string', 1, 3) do |value, *bounds|
      slice(check(value, Scheme::Vector).items, bounds).map { |char| check(char, Scheme::Character).value }.join
    end
    register('string->vector', 1, 3) do |value, *bounds|
      Scheme::Vector.new(slice(check(value, String), bounds).chars.map { |char| Scheme::Character.new(char) })
    end
    register('vector-fill!', 2, 4) do |value, fill, *bounds|
      mutable(check(value, Scheme::Vector)).items.fill(fill, slice_range(value.items.length, bounds))
      Scheme::UNSPECIFIED
    end
    register('string->utf8', 1, 3) { |value, *bounds| Scheme::Bytevector.new(slice(check(value, String), bounds).encode(Encoding::UTF_8).bytes) }
    register('utf8->string', 1, 3) do |value, *bounds|
      text = slice(check(value, Scheme::Bytevector).items, bounds).pack('C*').force_encoding(Encoding::UTF_8)
      raise Scheme::Error, 'invalid UTF-8 sequence' unless text.valid_encoding?

      text
    end
    iteration('vector-map', collect: true, kind: :vector)
    iteration('vector-for-each', collect: false, kind: :vector)
  end

  def slice(value, bounds)
    value[slice_range(value.length, bounds)]
  end

  def slice_range(size, bounds)
    start = index(bounds.fetch(0, 0), size, inclusive: true)
    finish = index(bounds.fetch(1, size), size, inclusive: true)
    raise Scheme::Error, 'slice end precedes start' if finish < start

    start...finish
  end

  def copy_into(target, offset, source)
    index(offset, target.length, inclusive: true)
    raise Scheme::Error, 'copy exceeds destination length' if offset + source.length > target.length

    target[offset, source.length] = source
  end
end
