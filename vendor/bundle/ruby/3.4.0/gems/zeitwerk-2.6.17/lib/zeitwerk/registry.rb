# frozen_string_literal: true

module Zeitwerk
  module Registry # :nodoc: all
    class << self
      # Keeps track of all loaders. Useful to broadcast messages and to prevent
      # them from being garbage collected.
      #
      # @private
      # @sig Array[Zeitwerk::Loader]
      attr_reader :loaders

      # Registers gem loaders to let `for_gem` be idempotent in case of reload.
      #
      # @private
      # @sig Hash[String, Zeitwerk::Loader]
      attr_reader :gem_loaders_by_root_file

      # Maps absolute paths to the loaders responsible for them.
      #
      # This information is used by our decorated `Kernel#require` to be able to
      # invoke callbacks and autovivify modules.
      #
      # @private
      # @sig Hash[String, Zeitwerk::Loader]
      attr_reader :autoloads

      # This hash table addresses an edge case in which an autoload is ignored.
      #
      # For example, let's suppose we want to autoload in a gem like this:
      #
      #   # lib/my_gem.rb
      #   loader = Zeitwerk::Loader.new
      #   loader.push_dir(__dir__)
      #   loader.setup
      #
      #   module MyGem
      #   end
      #
      # if you require "my_gem", as Bundler would do, this happens while setting
      # up autoloads:
      #
      #   1. Object.autoload?(:MyGem) returns `nil` because the autoload for
      #      the constant is issued by Zeitwerk while the same file is being
      #      required.
      #   2. The constant `MyGem` is undefined while setup runs.
      #
      # Therefore, a directory `lib/my_gem` would autovivify a module according to
      # the existing information. But that would be wrong.
      #
      # To overcome this fundamental limitation, we keep track of the constant
      # paths that are in this situation ---in the example above, "MyGem"--- and
      # take this collection into account for the autovivification logic.
      #
      # Note that you cannot generally address this by moving the setup code
      # below the constant definition, because we want libraries to be able to
      # use managed constants in the module body:
      #
      #   module MyGem
      #     include MyConcern
      #   end
      #
      # @private
      # @sig Hash[String, [String, Zeitwerk::Loader]]
      attr_reader :inceptions

      # Registers a loader.
      #
      # @private
      # @sig (Zeitwerk::Loader) -> void
      def register_loader(loader)
        loaders << loader
      end

      # @private
      # @sig (Zeitwerk::Loader) -> void
      def unregister_loader(loader)
        loaders.delete(loader)
        gem_loaders_by_root_file.delete_if { |_, l| l == loader }
        autoloads.delete_if { |_, l| l == loader }
        inceptions.delete_if { |_, (_, l)| l == loader }
      end

      # This method returns always a loader, the same instance for the same root
      # file. That is how Zeitwerk::Loader.for_gem is idempotent.
      #
      # @private
      # @sig (String) -> Zeitwerk::Loader
      def loader_for_gem(root_file, namespace:, warn_on_extra_files:)
        gem_loaders_by_root_file[root_file] ||= GemLoader.__new(root_file, namespace: namespace, warn_on_extra_files: warn_on_extra_files)
      end

      # @private
      # @sig (Zeitwerk::Loader, String) -> String
      def register_autoload(loader, abspath)
        autoloads[abspath] = loader
      end

      # @private
      # @sig (String) -> void
      def unregister_autoload(abspath)
        autoloads.delete(abspath)
      end

      # @private
      # @sig (String, String, Zeitwerk::Loader) -> void
      def register_inception(cpath, abspath, loader)
        inceptions[cpath] = [abspath, loader]
      end

      # @private
      # @sig (String) -> String?
      def inception?(cpath)
        if pair = inceptions[cpath]
          pair.first
        end
      end

      # @private
      # @sig (String) -> Zeitwerk::Loader?
      def loader_for(path)
        autoloads[path]
      end

      # @private
      # @sig (Zeitwerk::Loader) -> void
      def on_unload(loader)
        autoloads.delete_if { |_path, object| object == loader }
        inceptions.delete_if { |_cpath, (_path, object)| object == loader }
      end
    end

    @loaders                  = []
    @gem_loaders_by_root_file = {}
    @autoloads                = {}
    @inceptions               = {}
  end
end
