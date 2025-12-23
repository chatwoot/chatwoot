# frozen_string_literal: true

require "monitor"
require "set"

module Zeitwerk
  class Loader
    require_relative "loader/helpers"
    require_relative "loader/callbacks"
    require_relative "loader/config"
    require_relative "loader/eager_load"

    extend Internal

    include RealModName
    include Callbacks
    include Helpers
    include Config
    include EagerLoad

    MUTEX = Mutex.new
    private_constant :MUTEX

    # Maps absolute paths for which an autoload has been set ---and not
    # executed--- to their corresponding Zeitwerk::Cref object.
    #
    #   "/Users/fxn/blog/app/models/user.rb"          => #<Zeitwerk::Cref:... @mod=Object, @cname=:User, ...>,
    #   "/Users/fxn/blog/app/models/hotel/pricing.rb" => #<Zeitwerk::Cref:... @mod=Hotel, @cname=:Pricing, ...>,
    #   ...
    #
    # @sig Hash[String, Zeitwerk::Cref]
    attr_reader :autoloads
    internal :autoloads

    # We keep track of autoloaded directories to remove them from the registry
    # at the end of eager loading.
    #
    # Files are removed as they are autoloaded, but directories need to wait due
    # to concurrency (see why in Zeitwerk::Loader::Callbacks#on_dir_autoloaded).
    #
    # @sig Array[String]
    attr_reader :autoloaded_dirs
    internal :autoloaded_dirs

    # Stores metadata needed for unloading. Its entries look like this:
    #
    #   "Admin::Role" => [
    #     ".../admin/role.rb",
    #     #<Zeitwerk::Cref:... @mod=Admin, @cname=:Role, ...>
    #   ]
    #
    # The cpath as key helps implementing unloadable_cpath? The file name is
    # stored in order to be able to delete it from $LOADED_FEATURES, and the
    # cref is used to remove the constant from the parent class or module.
    #
    # If reloading is enabled, this hash is filled as constants are autoloaded
    # or eager loaded. Otherwise, the collection remains empty.
    #
    # @sig Hash[String, [String, Zeitwerk::Cref]]
    attr_reader :to_unload
    internal :to_unload

    # Maps namespace constant paths to their respective directories.
    #
    # For example, given this mapping:
    #
    #   "Admin" => [
    #     "/Users/fxn/blog/app/controllers/admin",
    #     "/Users/fxn/blog/app/models/admin",
    #     ...
    #   ]
    #
    # when `Admin` gets defined we know that it plays the role of a namespace
    # and that its children are spread over those directories. We'll visit them
    # to set up the corresponding autoloads.
    #
    # @sig Hash[String, Array[String]]
    attr_reader :namespace_dirs
    internal :namespace_dirs

    # A shadowed file is a file managed by this loader that is ignored when
    # setting autoloads because its matching constant is already taken.
    #
    # This private set is populated as we descend. For example, if the loader
    # has only scanned the top-level, `shadowed_files` does not have shadowed
    # files that may exist deep in the project tree yet.
    #
    # @sig Set[String]
    attr_reader :shadowed_files
    internal :shadowed_files

    # @sig Mutex
    attr_reader :mutex
    private :mutex

    # @sig Monitor
    attr_reader :dirs_autoload_monitor
    private :dirs_autoload_monitor

    def initialize
      super

      @autoloads       = {}
      @autoloaded_dirs = []
      @to_unload       = {}
      @namespace_dirs  = Hash.new { |h, cpath| h[cpath] = [] }
      @shadowed_files  = Set.new
      @setup           = false
      @eager_loaded    = false

      @mutex = Mutex.new
      @dirs_autoload_monitor = Monitor.new

      Registry.register_loader(self)
    end

    # Sets autoloads in the root namespaces.
    #
    # @sig () -> void
    def setup
      mutex.synchronize do
        break if @setup

        actual_roots.each do |root_dir, root_namespace|
          define_autoloads_for_dir(root_dir, root_namespace)
        end

        on_setup_callbacks.each(&:call)

        @setup = true
      end
    end

    # Removes loaded constants and configured autoloads.
    #
    # The objects the constants stored are no longer reachable through them. In
    # addition, since said objects are normally not referenced from anywhere
    # else, they are eligible for garbage collection, which would effectively
    # unload them.
    #
    # This method is public but undocumented. Main interface is `reload`, which
    # means `unload` + `setup`. This one is available to be used together with
    # `unregister`, which is undocumented too.
    #
    # @sig () -> void
    def unload
      mutex.synchronize do
        raise SetupRequired unless @setup

        # We are going to keep track of the files that were required by our
        # autoloads to later remove them from $LOADED_FEATURES, thus making them
        # loadable by Kernel#require again.
        #
        # Directories are not stored in $LOADED_FEATURES, keeping track of files
        # is enough.
        unloaded_files = Set.new

        autoloads.each do |abspath, cref|
          if cref.autoload?
            unload_autoload(cref)
          else
            # Could happen if loaded with require_relative. That is unsupported,
            # and the constant path would escape unloadable_cpath? This is just
            # defensive code to clean things up as much as we are able to.
            unload_cref(cref)
            unloaded_files.add(abspath) if ruby?(abspath)
          end
        end

        to_unload.each do |cpath, (abspath, cref)|
          unless on_unload_callbacks.empty?
            begin
              value = cref.get
            rescue ::NameError
              # Perhaps the user deleted the constant by hand, or perhaps an
              # autoload failed to define the expected constant but the user
              # rescued the exception.
            else
              run_on_unload_callbacks(cpath, value, abspath)
            end
          end

          unload_cref(cref)
          unloaded_files.add(abspath) if ruby?(abspath)
        end

        unless unloaded_files.empty?
          # Bootsnap decorates Kernel#require to speed it up using a cache and
          # this optimization does not check if $LOADED_FEATURES has the file.
          #
          # To make it aware of changes, the gem defines singleton methods in
          # $LOADED_FEATURES:
          #
          #   https://github.com/Shopify/bootsnap/blob/master/lib/bootsnap/load_path_cache/core_ext/loaded_features.rb
          #
          # Rails applications may depend on bootsnap, so for unloading to work
          # in that setting it is preferable that we restrict our API choice to
          # one of those methods.
          $LOADED_FEATURES.reject! { |file| unloaded_files.member?(file) }
        end

        autoloads.clear
        autoloaded_dirs.clear
        to_unload.clear
        namespace_dirs.clear
        shadowed_files.clear

        Registry.on_unload(self)
        ExplicitNamespace.__unregister_loader(self)

        @setup        = false
        @eager_loaded = false
      end
    end

    # Unloads all loaded code, and calls setup again so that the loader is able
    # to pick any changes in the file system.
    #
    # This method is not thread-safe, please see how this can be achieved by
    # client code in the README of the project.
    #
    # @raise [Zeitwerk::Error]
    # @sig () -> void
    def reload
      raise ReloadingDisabledError unless reloading_enabled?
      raise SetupRequired unless @setup

      unload
      recompute_ignored_paths
      recompute_collapse_dirs
      setup
    end

    # Returns a hash that maps the absolute paths of the managed files and
    # directories to their respective expected constant paths.
    #
    # @sig () -> Hash[String, String]
    def all_expected_cpaths
      result = {}

      actual_roots.each do |root_dir, root_namespace|
        queue = [[root_dir, real_mod_name(root_namespace)]]

        while (dir, cpath = queue.shift)
          result[dir] = cpath

          prefix = cpath == "Object" ? "" : cpath + "::"

          ls(dir) do |basename, abspath, ftype|
            if ftype == :file
              basename.delete_suffix!(".rb")
              result[abspath] = prefix + inflector.camelize(basename, abspath)
            else
              if collapse?(abspath)
                queue << [abspath, cpath]
              else
                queue << [abspath, prefix + inflector.camelize(basename, abspath)]
              end
            end
          end
        end
      end

      result
    end

    # @sig (String | Pathname) -> String?
    def cpath_expected_at(path)
      abspath = File.expand_path(path)

      raise Zeitwerk::Error.new("#{abspath} does not exist") unless File.exist?(abspath)

      return unless dir?(abspath) || ruby?(abspath)
      return if ignored_path?(abspath)

      paths = []

      if ruby?(abspath)
        basename = File.basename(abspath, ".rb")
        return if hidden?(basename)

        paths << [basename, abspath]
        walk_up_from = File.dirname(abspath)
      else
        walk_up_from = abspath
      end

      root_namespace = nil

      walk_up(walk_up_from) do |dir|
        break if root_namespace = roots[dir]
        return if ignored_path?(dir)

        basename = File.basename(dir)
        return if hidden?(basename)

        paths << [basename, abspath] unless collapse?(dir)
      end

      return unless root_namespace

      if paths.empty?
        real_mod_name(root_namespace)
      else
        cnames = paths.reverse_each.map { |b, a| cname_for(b, a) }

        if root_namespace == Object
          cnames.join("::")
        else
          "#{real_mod_name(root_namespace)}::#{cnames.join("::")}"
        end
      end
    end

    # Says if the given constant path would be unloaded on reload. This
    # predicate returns `false` if reloading is disabled.
    #
    # @sig (String) -> bool
    def unloadable_cpath?(cpath)
      to_unload.key?(cpath)
    end

    # Returns an array with the constant paths that would be unloaded on reload.
    # This predicate returns an empty array if reloading is disabled.
    #
    # @sig () -> Array[String]
    def unloadable_cpaths
      to_unload.keys.freeze
    end

    # This is a dangerous method.
    #
    # @experimental
    # @sig () -> void
    def unregister
      Registry.unregister_loader(self)
      ExplicitNamespace.__unregister_loader(self)
    end

    # The return value of this predicate is only meaningful if the loader has
    # scanned the file. This is the case in the spots where we use it.
    #
    # @sig (String) -> Boolean
    internal def shadowed_file?(file)
      shadowed_files.member?(file)
    end

    # --- Class methods ---------------------------------------------------------------------------

    class << self
      include RealModName

      # @sig #call | #debug | nil
      attr_accessor :default_logger

      # This is a shortcut for
      #
      #   require "zeitwerk"
      #
      #   loader = Zeitwerk::Loader.new
      #   loader.tag = File.basename(__FILE__, ".rb")
      #   loader.inflector = Zeitwerk::GemInflector.new(__FILE__)
      #   loader.push_dir(__dir__)
      #
      # except that this method returns the same object in subsequent calls from
      # the same file, in the unlikely case the gem wants to be able to reload.
      #
      # This method returns a subclass of Zeitwerk::Loader, but the exact type
      # is private, client code can only rely on the interface.
      #
      # @sig (bool) -> Zeitwerk::GemLoader
      def for_gem(warn_on_extra_files: true)
        called_from = caller_locations(1, 1).first.path
        Registry.loader_for_gem(called_from, namespace: Object, warn_on_extra_files: warn_on_extra_files)
      end

      # This is a shortcut for
      #
      #   require "zeitwerk"
      #
      #   loader = Zeitwerk::Loader.new
      #   loader.tag = namespace.name + "-" + File.basename(__FILE__, ".rb")
      #   loader.inflector = Zeitwerk::GemInflector.new(__FILE__)
      #   loader.push_dir(__dir__, namespace: namespace)
      #
      # except that this method returns the same object in subsequent calls from
      # the same file, in the unlikely case the gem wants to be able to reload.
      #
      # This method returns a subclass of Zeitwerk::Loader, but the exact type
      # is private, client code can only rely on the interface.
      #
      # @sig (bool) -> Zeitwerk::GemLoader
      def for_gem_extension(namespace)
        unless namespace.is_a?(Module) # Note that Class < Module.
          raise Zeitwerk::Error, "#{namespace.inspect} is not a class or module object, should be"
        end

        unless real_mod_name(namespace)
          raise Zeitwerk::Error, "extending anonymous namespaces is unsupported"
        end

        called_from = caller_locations(1, 1).first.path
        Registry.loader_for_gem(called_from, namespace: namespace, warn_on_extra_files: false)
      end

      # Broadcasts `eager_load` to all loaders. Those that have not been setup
      # are skipped.
      #
      # @sig () -> void
      def eager_load_all
        Registry.loaders.each do |loader|
          begin
            loader.eager_load
          rescue SetupRequired
            # This is fine, we eager load what can be eager loaded.
          end
        end
      end

      # Broadcasts `eager_load_namespace` to all loaders. Those that have not
      # been setup are skipped.
      #
      # @sig (Module) -> void
      def eager_load_namespace(mod)
        Registry.loaders.each do |loader|
          begin
            loader.eager_load_namespace(mod)
          rescue SetupRequired
            # This is fine, we eager load what can be eager loaded.
          end
        end
      end

      # Returns an array with the absolute paths of the root directories of all
      # registered loaders. This is a read-only collection.
      #
      # @sig () -> Array[String]
      def all_dirs
        Registry.loaders.flat_map(&:dirs).freeze
      end
    end

    # @sig (String, Module) -> void
    private def define_autoloads_for_dir(dir, parent)
      ls(dir) do |basename, abspath, ftype|
        if ftype == :file
          basename.delete_suffix!(".rb")
          cref = Cref.new(parent, cname_for(basename, abspath))
          autoload_file(cref, abspath)
        else
          if collapse?(abspath)
            define_autoloads_for_dir(abspath, parent)
          else
            cref = Cref.new(parent, cname_for(basename, abspath))
            autoload_subdir(cref, abspath)
          end
        end
      end
    end

    # @sig (Module, Symbol, String) -> void
    private def autoload_subdir(cref, subdir)
      if autoload_path = autoload_path_set_by_me_for?(cref)
        if ruby?(autoload_path)
          # Scanning visited a Ruby file first, and now a directory for the same
          # constant has been found. This means we are dealing with an explicit
          # namespace whose definition was seen first.
          #
          # Registering is idempotent, and we have to keep the autoload pointing
          # to the file. This may run again if more directories are found later
          # on, no big deal.
          register_explicit_namespace(cref.path)
        end
        # If the existing autoload points to a file, it has to be preserved, if
        # not, it is fine as it is. In either case, we do not need to override.
        # Just remember the subdirectory conforms this namespace.
        namespace_dirs[cref.path] << subdir
      elsif !cref.defined?
        # First time we find this namespace, set an autoload for it.
        namespace_dirs[cref.path] << subdir
        define_autoload(cref, subdir)
      else
        # For whatever reason the constant that corresponds to this namespace has
        # already been defined, we have to recurse.
        log("the namespace #{cref.path} already exists, descending into #{subdir}") if logger
        define_autoloads_for_dir(subdir, cref.get)
      end
    end

    # @sig (Module, Symbol, String) -> void
    private def autoload_file(cref, file)
      if autoload_path = cref.autoload? || Registry.inception?(cref.path)
        # First autoload for a Ruby file wins, just ignore subsequent ones.
        if ruby?(autoload_path)
          shadowed_files << file
          log("file #{file} is ignored because #{autoload_path} has precedence") if logger
        else
          promote_namespace_from_implicit_to_explicit(dir: autoload_path, file: file, cref: cref)
        end
      elsif cref.defined?
        shadowed_files << file
        log("file #{file} is ignored because #{cref.path} is already defined") if logger
      else
        define_autoload(cref, file)
      end
    end

    # `dir` is the directory that would have autovivified a namespace. `file` is
    # the file where we've found the namespace is explicitly defined.
    #
    # @sig (dir: String, file: String, cref: Zeitwerk::Cref) -> void
    private def promote_namespace_from_implicit_to_explicit(dir:, file:, cref:)
      autoloads.delete(dir)
      Registry.unregister_autoload(dir)

      log("earlier autoload for #{cref.path} discarded, it is actually an explicit namespace defined in #{file}") if logger

      define_autoload(cref, file)
      register_explicit_namespace(cref.path)
    end

    # @sig (Module, Symbol, String) -> void
    private def define_autoload(cref, abspath)
      cref.autoload(abspath)

      if logger
        if ruby?(abspath)
          log("autoload set for #{cref.path}, to be loaded from #{abspath}")
        else
          log("autoload set for #{cref.path}, to be autovivified from #{abspath}")
        end
      end

      autoloads[abspath] = cref
      Registry.register_autoload(self, abspath)

      # See why in the documentation of Zeitwerk::Registry.inceptions.
      unless cref.autoload?
        Registry.register_inception(cref.path, abspath, self)
      end
    end

    # @sig (Module, Symbol) -> String?
    private def autoload_path_set_by_me_for?(cref)
      if autoload_path = cref.autoload?
        autoload_path if autoloads.key?(autoload_path)
      else
        Registry.inception?(cref.path)
      end
    end

    # @sig (String) -> void
    private def register_explicit_namespace(cpath)
      ExplicitNamespace.__register(cpath, self)
    end

    # @sig (String) -> void
    private def raise_if_conflicting_directory(dir)
      MUTEX.synchronize do
        dir_slash = dir + "/"

        Registry.loaders.each do |loader|
          next if loader == self
          next if loader.__ignores?(dir)

          loader.__roots.each_key do |root_dir|
            next if ignores?(root_dir)

            root_dir_slash = root_dir + "/"
            if dir_slash.start_with?(root_dir_slash) || root_dir_slash.start_with?(dir_slash)
              require "pp" # Needed for pretty_inspect, even in Ruby 2.5.
              raise Error,
                "loader\n\n#{pretty_inspect}\n\nwants to manage directory #{dir}," \
                " which is already managed by\n\n#{loader.pretty_inspect}\n"
            end
          end
        end
      end
    end

    # @sig (String, Object, String) -> void
    private def run_on_unload_callbacks(cpath, value, abspath)
      # Order matters. If present, run the most specific one.
      on_unload_callbacks[cpath]&.each { |c| c.call(value, abspath) }
      on_unload_callbacks[:ANY]&.each { |c| c.call(cpath, value, abspath) }
    end

    # @sig (Module, Symbol) -> void
    private def unload_autoload(cref)
      cref.remove
      log("autoload for #{cref.path} removed") if logger
    end

    # @sig (Module, Symbol) -> void
    private def unload_cref(cref)
      # Let's optimistically remove_const. The way we use it, this is going to
      # succeed always if all is good.
      cref.remove
    rescue ::NameError
      # There are a few edge scenarios in which this may happen. If the constant
      # is gone, that is OK, anyway.
    else
      log("#{cref.path} unloaded") if logger
    end
  end
end
