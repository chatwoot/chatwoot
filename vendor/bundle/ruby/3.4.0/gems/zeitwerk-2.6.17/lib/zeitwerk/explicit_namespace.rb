# frozen_string_literal: true

module Zeitwerk
  # Centralizes the logic for the trace point used to detect the creation of
  # explicit namespaces, needed to descend into matching subdirectories right
  # after the constant has been defined.
  #
  # The implementation assumes an explicit namespace is managed by one loader.
  # Loaders that reopen namespaces owned by other projects are responsible for
  # loading their constant before setup. This is documented.
  module ExplicitNamespace # :nodoc: all
    class << self
      include RealModName
      extend Internal

      # Maps constant paths that correspond to explicit namespaces according to
      # the file system, to the loader responsible for them.
      #
      # @sig Hash[String, Zeitwerk::Loader]
      attr_reader :cpaths
      private :cpaths

      # @sig Mutex
      attr_reader :mutex
      private :mutex

      # @sig TracePoint
      attr_reader :tracer
      private :tracer

      # Asserts `cpath` corresponds to an explicit namespace for which `loader`
      # is responsible.
      #
      # @sig (String, Zeitwerk::Loader) -> void
      internal def register(cpath, loader)
        mutex.synchronize do
          cpaths[cpath] = loader
          # We check enabled? because, looking at the C source code, enabling an
          # enabled tracer does not seem to be a simple no-op.
          tracer.enable unless tracer.enabled?
        end
      end

      # @sig (Zeitwerk::Loader) -> void
      internal def unregister_loader(loader)
        cpaths.delete_if { |_cpath, l| l == loader }
        disable_tracer_if_unneeded
      end

      # This is an internal method only used by the test suite.
      #
      # @sig (String) -> bool
      internal def registered?(cpath)
        cpaths.key?(cpath)
      end

      # @sig () -> void
      private def disable_tracer_if_unneeded
        mutex.synchronize do
          tracer.disable if cpaths.empty?
        end
      end

      # @sig (TracePoint) -> void
      private def tracepoint_class_callback(event)
        # If the class is a singleton class, we won't do anything with it so we
        # can bail out immediately. This is several orders of magnitude faster
        # than accessing its name.
        return if event.self.singleton_class?

        # It might be tempting to return if name.nil?, to avoid the computation
        # of a hash code and delete call. But Ruby does not trigger the :class
        # event on Class.new or Module.new, so that would incur in an extra call
        # for nothing.
        #
        # On the other hand, if we were called, cpaths is not empty. Otherwise
        # the tracer is disabled. So we do need to go ahead with the hash code
        # computation and delete call.
        if loader = cpaths.delete(real_mod_name(event.self))
          loader.on_namespace_loaded(event.self)
          disable_tracer_if_unneeded
        end
      end
    end

    @cpaths = {}
    @mutex  = Mutex.new

    # We go through a method instead of defining a block mainly to have a better
    # label when profiling.
    @tracer = TracePoint.new(:class, &method(:tracepoint_class_callback))
  end
end
