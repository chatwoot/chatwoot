require 'scheme'

# A flat object graph preserves shared lexical cells, mutable lists and cycles.
# Standard environments are named roots, never serialized native Ruby closures.
# Restoring state reconnects values; it never executes saved programs or actions.
class Captain::Apropos::Codec
  FORMAT = 'scheme-v2'.freeze

  def self.dump(value, roots: {})
    new(roots).dump(value)
  end

  def self.load(value, roots: {})
    new(roots).load(value)
  end

  def initialize(roots)
    @roots = roots
  end

  def dump(value)
    @seen = {}.compare_by_identity
    @pending = []
    root = reference(value)
    nodes = []
    index = 0
    while index < @pending.length
      nodes << encode(@pending[index])
      index += 1
    end
    { 'format' => FORMAT, 'root' => root, 'nodes' => nodes }
  end

  def load(value)
    return legacy(value, {}) unless value.is_a?(Hash) && value['format'] == FORMAT

    nodes = value.fetch('nodes')
    @objects = nodes.map { |node| allocate_node(node) }
    nodes.each_with_index { |node, index| populate(@objects[index], node) }
    initialize_closures(nodes)
    freeze_nodes(nodes)
    dereference(value.fetch('root'))
  end

  private

  # These passes must remain separate: closures can refer to pairs populated
  # later in the graph, and immutable nodes cannot be frozen before population.
  def initialize_closures(nodes)
    nodes.each_with_index do |node, index|
      next unless node['type'] == 'closure'

      @objects[index].send(:initialize, dereference(node.fetch('parameters')), dereference(node.fetch('body')),
                           dereference(node.fetch('environment')))
    end
  end

  def freeze_nodes(nodes)
    nodes.each_with_index do |node, index|
      next unless node['frozen']

      object = @objects[index]
      object.items.freeze if object.is_a?(::Scheme::Vector) || object.is_a?(::Scheme::Bytevector)
      object.freeze
    end
  end

  def reference(value)
    name = @roots.key(value)
    return { 'root' => name } if name
    return { 'singleton' => 'empty' } if value.equal?(::Scheme::EMPTY)
    return { 'singleton' => 'unspecified' } if value.equal?(::Scheme::UNSPECIFIED)
    return { 'singleton' => 'uninitialized' } if value.equal?(::Scheme::UNINITIALIZED)
    return value if value.nil? || value == true || value == false || value.is_a?(Integer)
    return { 'symbol' => value.to_s } if value.is_a?(Symbol)

    unless @seen.key?(value)
      @seen[value] = @pending.size
      @pending << value
    end
    { 'ref' => @seen.fetch(value) }
  end

  def encode(value)
    node = case value
           when String then { 'type' => 'string', 'value' => value }
           when Float then { 'type' => 'float', 'value' => value.to_s }
           when Rational then { 'type' => 'rational', 'parts' => [value.numerator, value.denominator] }
           when Complex then { 'type' => 'complex', 'value' => ::Scheme.write(value) }
           when Hash then { 'type' => 'hash', 'entries' => value.map { |key, item| [reference(key), reference(item)] } }
           when Array then { 'type' => 'array', 'items' => value.map { |item| reference(item) } }
           when ::Scheme::Pair then { 'type' => 'pair', 'car' => reference(value.car), 'cdr' => reference(value.cdr) }
           when ::Scheme::Vector, ::Scheme::Bytevector
             { 'type' => value.is_a?(::Scheme::Bytevector) ? 'bytevector' : 'vector', 'items' => value.items.map { |item| reference(item) } }
           when ::Scheme::Character then { 'type' => 'character', 'value' => value.value }
           when ::Scheme::Environment
             { 'type' => 'environment', 'parent' => reference(value.parent), 'bindings' => reference(value.bindings) }
           when ::Scheme::Environment::Cell then { 'type' => 'cell', 'value' => reference(value.value) }
           when ::Scheme::Closure
             { 'type' => 'closure', 'parameters' => reference(value.parameters), 'body' => reference(value.body),
               'environment' => reference(value.environment) }
           when ::Scheme::CaseClosure then { 'type' => 'case-closure', 'clauses' => reference(value.clauses) }
           when ::Scheme::Native, ::Scheme::Syntax
             unless @roots['builtins']&.cell(value.name.to_sym)&.value.equal?(value)
               raise Captain::Apropos::Error, 'Cannot persist a runtime-generated host procedure; save an ordinary Scheme lambda instead.'
             end

             { 'type' => 'builtin', 'name' => value.name.to_s }
           when ::Scheme::MultipleValues then { 'type' => 'multiple-values', 'items' => reference(value.items) }
           else
             raise Captain::Apropos::Error, "Cannot persist #{value.class.name}. Keep data and lambdas in saved bindings, not live control state."
           end
    node.merge('frozen' => value.frozen?)
  end

  def dereference(value)
    return value unless value.is_a?(Hash)
    return @roots.fetch(value['root']) if value.key?('root')
    return @objects.fetch(value['ref']) if value.key?('ref')
    return value.fetch('symbol').to_sym if value.key?('symbol')

    { 'empty' => ::Scheme::EMPTY, 'unspecified' => ::Scheme::UNSPECIFIED, 'uninitialized' => ::Scheme::UNINITIALIZED }.fetch(value.fetch('singleton'))
  end

  def allocate_node(node)
    case node.fetch('type')
    when 'string' then node.fetch('value').dup
    when 'float'
      { 'Infinity' => Float::INFINITY, '-Infinity' => -Float::INFINITY, 'NaN' => Float::NAN }.fetch(node['value']) { Float(node.fetch('value')) }
    when 'rational' then Rational(*node.fetch('parts'))
    when 'complex' then ::Scheme::Numbers.parse(node.fetch('value'))
    when 'hash' then {}
    when 'array' then []
    when 'pair' then ::Scheme::Pair.new(nil)
    when 'vector' then ::Scheme::Vector.new([])
    when 'bytevector' then ::Scheme::Bytevector.new([])
    when 'character' then ::Scheme::Character.new(node.fetch('value'))
    when 'environment' then ::Scheme::Environment.new
    when 'cell' then ::Scheme::Environment::Cell.new
    when 'closure' then ::Scheme::Closure.allocate
    when 'case-closure' then ::Scheme::CaseClosure.new
    when 'multiple-values' then ::Scheme::MultipleValues.new
    when 'builtin' then @roots.fetch('builtins').get(node.fetch('name').to_sym)
    else raise Captain::Apropos::Error, 'Unknown saved Scheme value'
    end
  end

  def populate(object, node)
    case node.fetch('type')
    when 'hash' then node.fetch('entries').each { |key, value| object[dereference(key)] = dereference(value) }
    when 'array' then object.concat(node.fetch('items').map { |item| dereference(item) })
    when 'pair'
      object.car = dereference(node.fetch('car'))
      object.cdr = dereference(node.fetch('cdr'))
    when 'vector', 'bytevector' then object.items.concat(node.fetch('items').map { |item| dereference(item) })
    when 'environment'
      object.instance_variable_set(:@parent, dereference(node.fetch('parent')))
      object.instance_variable_set(:@bindings, dereference(node.fetch('bindings')))
    when 'cell' then object.value = dereference(node.fetch('value'))
    when 'closure'
      # Parameter lists are graph nodes and may be populated after this closure.
      # Defer initialization until every referenced pair and body array exists.
    when 'case-closure' then object.clauses = dereference(node.fetch('clauses'))
    when 'multiple-values' then object.items = dereference(node.fetch('items'))
    end
  end

  # Old sessions contain only the previous interpreter's data/closure encoding.
  # Translate these values once; no old evaluator or source replay is retained.
  def legacy(value, seen)
    return ::Scheme.list(value.map { |item| legacy(item, seen) }) if value.is_a?(Array)
    return value unless value.is_a?(Hash)

    case value.fetch('type')
    when 'symbol' then value.fetch('value').to_sym
    when 'hash' then value.fetch('value').to_h { |key, item| [legacy(key, seen), legacy(item, seen)] }
    when 'reference' then seen.fetch(value.fetch('id'))
    when 'scope'
      scope = ::Scheme::Environment.new
      seen[value['id']] = scope if value.key?('id')
      scope.instance_variable_set(:@parent, legacy(value.fetch('parent'), seen) || @roots.fetch('globals'))
      legacy(value.fetch('values'), seen).each { |name, item| scope.define(name, item) }
      scope
    when 'closure'
      closure = ::Scheme::Closure.allocate
      seen[value['id']] = closure if value.key?('id')
      environment = legacy(value.fetch('locals'), seen) || @roots.fetch('globals')
      if environment.is_a?(Hash)
        locals = environment
        environment = ::Scheme::Environment.new(@roots.fetch('globals'))
        locals.each { |name, item| environment.define(name, item) }
      end
      closure.send(:initialize, legacy(value.fetch('parameters'), seen), ::Scheme.to_a(legacy(value.fetch('body'), seen)), environment)
      closure
    else raise Captain::Apropos::Error, 'Unknown saved Scheme value'
    end
  end
end
