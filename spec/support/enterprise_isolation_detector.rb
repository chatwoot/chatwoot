# Finds modules outside the Enterprise tree that are prepended in front of a method Enterprise
# defines, on a class or on its singleton class, so both `Foo#bar` and `Foo.bar` are checked.
# `Module#instance_methods` already lists public and protected methods; private ones are added
# by hand. `root` is the directory whose files count as Enterprise, which lets a spec point it at
# a fixture tree instead of enterprise/.
module EnterpriseIsolationDetector
  NAME_OF = Module.instance_method(:name)
  ANCESTORS_OF = Module.instance_method(:ancestors)

  module_function

  def violations(root:, modules: ObjectSpace.each_object(Module))
    modules.flat_map do |klass|
      next [] if klass.singleton_class? || NAME_OF.bind_call(klass).nil?

      [[klass, '#'], [klass.singleton_class, '.']].flat_map { |target, sep| overrides_on(target, sep, root) }
    end.uniq
  end

  def overrides_on(target, separator, root)
    ANCESTORS_OF.bind_call(target).take_while { |ancestor| ancestor != target }.flat_map do |mod|
      next [] if NAME_OF.bind_call(mod).to_s.start_with?('Enterprise::')

      (mod.instance_methods(false) + mod.private_instance_methods(false)).filter_map do |method_name|
        override_label(target, mod, method_name, separator, root)
      end
    end
  end

  def override_label(target, mod, method_name, separator, root)
    return if inside?(mod.instance_method(method_name).source_location, root)

    overridden = overridden_method(target, mod, method_name)
    return unless overridden && inside?(overridden.source_location, root)

    "#{NAME_OF.bind_call(mod) || mod.inspect}#{separator}#{method_name} over #{overridden.owner}"
  end

  # The method a prepended module's own definition stands in front of, which is the one that runs
  # when it calls `super`.
  def overridden_method(target, mod, name)
    method = target.instance_method(name)
    method = method.super_method while method && method.owner != mod
    method&.super_method
  end

  def inside?(source, root)
    source.present? && source.first.start_with?("#{root}/")
  end
end
