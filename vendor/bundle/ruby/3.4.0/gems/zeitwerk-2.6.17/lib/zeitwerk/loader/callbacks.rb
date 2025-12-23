# frozen_string_literal: true

module Zeitwerk::Loader::Callbacks
  include Zeitwerk::RealModName
  extend Zeitwerk::Internal

  # Invoked from our decorated Kernel#require when a managed file is autoloaded.
  #
  # @sig (String) -> void
  internal def on_file_autoloaded(file)
    cref = autoloads.delete(file)

    Zeitwerk::Registry.unregister_autoload(file)

    if cref.defined?
      log("constant #{cref.path} loaded from file #{file}") if logger
      to_unload[cref.path] = [file, cref] if reloading_enabled?
      run_on_load_callbacks(cref.path, cref.get, file) unless on_load_callbacks.empty?
    else
      msg = "expected file #{file} to define constant #{cref.path}, but didn't"
      log(msg) if logger

      # Ruby still keeps the autoload defined, but we remove it because the
      # contract in Zeitwerk is more strict.
      cref.remove

      # Since the expected constant was not defined, there is nothing to unload.
      # However, if the exception is rescued and reloading is enabled, we still
      # need to deleted the file from $LOADED_FEATURES.
      to_unload[cref.path] = [file, cref] if reloading_enabled?

      raise Zeitwerk::NameError.new(msg, cref.cname)
    end
  end

  # Invoked from our decorated Kernel#require when a managed directory is
  # autoloaded.
  #
  # @sig (String) -> void
  internal def on_dir_autoloaded(dir)
    # Module#autoload does not serialize concurrent requires in CRuby < 3.2, and
    # we handle directories ourselves without going through Kernel#require, so
    # the callback needs to account for concurrency.
    #
    # Multi-threading would introduce a race condition here in which thread t1
    # autovivifies the module, and while autoloads for its children are being
    # set, thread t2 autoloads the same namespace.
    #
    # Without the mutex and subsequent delete call, t2 would reset the module.
    # That not only would reassign the constant (undesirable per se) but, worse,
    # the module object created by t2 wouldn't have any of the autoloads for its
    # children, since t1 would have correctly deleted its namespace_dirs entry.
    dirs_autoload_monitor.synchronize do
      if cref = autoloads.delete(dir)
        implicit_namespace = cref.set(Module.new)
        cpath = implicit_namespace.name
        log("module #{cpath} autovivified from directory #{dir}") if logger

        to_unload[cpath] = [dir, cref] if reloading_enabled?

        # We don't unregister `dir` in the registry because concurrent threads
        # wouldn't find a loader associated to it in Kernel#require and would
        # try to require the directory. Instead, we are going to keep track of
        # these to be able to unregister later if eager loading.
        autoloaded_dirs << dir

        on_namespace_loaded(implicit_namespace)

        run_on_load_callbacks(cpath, implicit_namespace, dir) unless on_load_callbacks.empty?
      end
    end
  end

  # Invoked when a class or module is created or reopened, either from the
  # tracer or from module autovivification. If the namespace has matching
  # subdirectories, we descend into them now.
  #
  # @private
  # @sig (Module) -> void
  def on_namespace_loaded(namespace)
    if dirs = namespace_dirs.delete(real_mod_name(namespace))
      dirs.each do |dir|
        define_autoloads_for_dir(dir, namespace)
      end
    end
  end

  private

  # @sig (String, Object) -> void
  def run_on_load_callbacks(cpath, value, abspath)
    # Order matters. If present, run the most specific one.
    callbacks = reloading_enabled? ? on_load_callbacks[cpath] : on_load_callbacks.delete(cpath)
    callbacks&.each { |c| c.call(value, abspath) }

    callbacks = on_load_callbacks[:ANY]
    callbacks&.each { |c| c.call(cpath, value, abspath) }
  end
end
