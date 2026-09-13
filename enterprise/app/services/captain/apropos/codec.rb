# Persist values, never replay programs that may have performed writes.
class Captain::Apropos::Codec
  class << self
    def dump(value, seen = {}.compare_by_identity)
      case value
      when Captain::Apropos::Scope, Captain::Apropos::Scheme::Closure then dump_reference(value, seen)
      when Symbol then { 'type' => 'symbol', 'value' => value.to_s }
      when Hash then dump_hash(value, seen)
      when Array then value.map { |item| dump(item, seen) }
      when String, Numeric, TrueClass, FalseClass, NilClass then value
      else
        raise Captain::Apropos::Error, 'Cannot persist this value; bind data or Scheme lambdas instead of host procedures'
      end
    end

    def load(value, seen = {})
      return value.map { |item| load(item, seen) } if value.is_a?(Array)
      return value unless value.is_a?(Hash)

      load_tagged(value, seen)
    end

    private

    def load_tagged(value, seen)
      case value.fetch('type')
      when 'symbol' then value.fetch('value').to_sym
      when 'hash' then value.fetch('value').to_h { |key, item| [load(key, seen), load(item, seen)] }
      when 'reference' then seen.fetch(value.fetch('id'))
      when 'closure', 'scope' then load_environment(value, seen)
      else
        raise Captain::Apropos::Error, 'Unknown stored value'
      end
    end

    def dump_hash(value, seen)
      { 'type' => 'hash', 'value' => value.map { |key, item| [dump(key, seen), dump(item, seen)] } }
    end

    def dump_reference(value, seen)
      return { 'type' => 'reference', 'id' => seen.fetch(value) } if seen.key?(value)

      seen[value] = seen.size
      dump_environment(value, seen).merge('id' => seen.fetch(value))
    end

    def dump_environment(value, seen)
      if value.is_a?(Captain::Apropos::Scope)
        { 'type' => 'scope', 'values' => dump(value.values, seen), 'parent' => dump(value.parent, seen) }
      else
        { 'type' => 'closure', 'parameters' => dump(value.parameters, seen), 'body' => dump(value.body, seen),
          'locals' => dump(value.locals, seen) }
      end
    end

    def load_environment(value, seen)
      object = value.fetch('type') == 'scope' ? Captain::Apropos::Scope.new : Captain::Apropos::Scheme::Closure.new
      seen[value.fetch('id')] = object if value.key?('id')
      if object.is_a?(Captain::Apropos::Scope)
        object.values = load(value.fetch('values'), seen)
        object.parent = load(value.fetch('parent'), seen)
      else
        object.parameters = load(value.fetch('parameters'), seen)
        object.body = load(value.fetch('body'), seen)
        locals = load(value.fetch('locals'), seen)
        object.locals = locals.is_a?(Hash) ? Captain::Apropos::Scope.new(locals) : locals
      end
      object
    end
  end
end
