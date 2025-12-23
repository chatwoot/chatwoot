# frozen_string_literal: true

require "set"
require "securerandom"

module Zeitwerk::Loader::Config
  extend Zeitwerk::Internal
  include Zeitwerk::RealModName

  # @sig #camelize
  attr_accessor :inflector

  # @sig #call | #debug | nil
  attr_accessor :logger

  # Absolute paths of the root directories, mapped to their respective root namespaces:
  #
  #   "/Users/fxn/blog/app/channels" => Object,
  #   "/Users/fxn/blog/app/adapters" => ActiveJob::QueueAdapters,
  #   ...
  #
  # Stored in a hash to preserve order, easily handle duplicates, and have a
  # fast lookup by directory.
  #
  # This is a private collection maintained by the loader. The public
  # interface for it is `push_dir` and `dirs`.
  #
  # @sig Hash[String, Module]
  attr_reader :roots
  internal :roots

  # Absolute paths of files, directories, or glob patterns to be totally
  # ignored.
  #
  # @sig Set[String]
  attr_reader :ignored_glob_patterns
  private :ignored_glob_patterns

  # The actual collection of absolute file and directory names at the time the
  # ignored glob patterns were expanded. Computed on setup, and recomputed on
  # reload.
  #
  # @sig Set[String]
  attr_reader :ignored_paths
  private :ignored_paths

  # Absolute paths of directories or glob patterns to be collapsed.
  #
  # @sig Set[String]
  attr_reader :collapse_glob_patterns
  private :collapse_glob_patterns

  # The actual collection of absolute directory names at the time the collapse
  # glob patterns were expanded. Computed on setup, and recomputed on reload.
  #
  # @sig Set[String]
  attr_reader :collapse_dirs
  private :collapse_dirs

  # Absolute paths of files or directories not to be eager loaded.
  #
  # @sig Set[String]
  attr_reader :eager_load_exclusions
  private :eager_load_exclusions

  # User-oriented callbacks to be fired on setup and on reload.
  #
  # @sig Array[{ () -> void }]
  attr_reader :on_setup_callbacks
  private :on_setup_callbacks

  # User-oriented callbacks to be fired when a constant is loaded.
  #
  # @sig Hash[String, Array[{ (Object, String) -> void }]]
  #      Hash[Symbol, Array[{ (String, Object, String) -> void }]]
  attr_reader :on_load_callbacks
  private :on_load_callbacks

  # User-oriented callbacks to be fired before constants are removed.
  #
  # @sig Hash[String, Array[{ (Object, String) -> void }]]
  #      Hash[Symbol, Array[{ (String, Object, String) -> void }]]
  attr_reader :on_unload_callbacks
  private :on_unload_callbacks

  def initialize
    @inflector              = Zeitwerk::Inflector.new
    @logger                 = self.class.default_logger
    @tag                    = SecureRandom.hex(3)
    @initialized_at         = Time.now
    @roots                  = {}
    @ignored_glob_patterns  = Set.new
    @ignored_paths          = Set.new
    @collapse_glob_patterns = Set.new
    @collapse_dirs          = Set.new
    @eager_load_exclusions  = Set.new
    @reloading_enabled      = false
    @on_setup_callbacks     = []
    @on_load_callbacks      = {}
    @on_unload_callbacks    = {}
  end

  # Pushes `path` to the list of root directories.
  #
  # Raises `Zeitwerk::Error` if `path` does not exist, or if another loader in
  # the same process already manages that directory or one of its ascendants or
  # descendants.
  #
  # @raise [Zeitwerk::Error]
  # @sig (String | Pathname, Module) -> void
  def push_dir(path, namespace: Object)
    unless namespace.is_a?(Module) # Note that Class < Module.
      raise Zeitwerk::Error, "#{namespace.inspect} is not a class or module object, should be"
    end

    unless real_mod_name(namespace)
      raise Zeitwerk::Error, "root namespaces cannot be anonymous"
    end

    abspath = File.expand_path(path)
    if dir?(abspath)
      raise_if_conflicting_directory(abspath)
      roots[abspath] = namespace
    else
      raise Zeitwerk::Error, "the root directory #{abspath} does not exist"
    end
  end

  # Returns the loader's tag.
  #
  # Implemented as a method instead of via attr_reader for symmetry with the
  # writer below.
  #
  # @sig () -> String
  def tag
    @tag
  end

  # Sets a tag for the loader, useful for logging.
  #
  # @sig (#to_s) -> void
  def tag=(tag)
    @tag = tag.to_s
  end

  # If `namespaces` is falsey (default), returns an array with the absolute
  # paths of the root directories as strings. If truthy, returns a hash table
  # instead. Keys are the absolute paths of the root directories as strings,
  # values are their corresponding namespaces, class or module objects.
  #
  # If `ignored` is falsey (default), ignored root directories are filtered out.
  #
  # These are read-only collections, please add to them with `push_dir`.
  #
  # @sig () -> Array[String] | Hash[String, Module]
  def dirs(namespaces: false, ignored: false)
    if namespaces
      if ignored || ignored_paths.empty?
        roots.clone
      else
        roots.reject { |root_dir, _namespace| ignored_path?(root_dir) }
      end
    else
      if ignored || ignored_paths.empty?
        roots.keys
      else
        roots.keys.reject { |root_dir| ignored_path?(root_dir) }
      end
    end.freeze
  end

  # You need to call this method before setup in order to be able to reload.
  # There is no way to undo this, either you want to reload or you don't.
  #
  # @raise [Zeitwerk::Error]
  # @sig () -> void
  def enable_reloading
    mutex.synchronize do
      break if @reloading_enabled

      if @setup
        raise Zeitwerk::Error, "cannot enable reloading after setup"
      else
        @reloading_enabled = true
      end
    end
  end

  # @sig () -> bool
  def reloading_enabled?
    @reloading_enabled
  end

  # Let eager load ignore the given files or directories. The constants defined
  # in those files are still autoloadable.
  #
  # @sig (*(String | Pathname | Array[String | Pathname])) -> void
  def do_not_eager_load(*paths)
    mutex.synchronize { eager_load_exclusions.merge(expand_paths(paths)) }
  end

  # Configure files, directories, or glob patterns to be totally ignored.
  #
  # @sig (*(String | Pathname | Array[String | Pathname])) -> void
  def ignore(*glob_patterns)
    glob_patterns = expand_paths(glob_patterns)
    mutex.synchronize do
      ignored_glob_patterns.merge(glob_patterns)
      ignored_paths.merge(expand_glob_patterns(glob_patterns))
    end
  end

  # Configure directories or glob patterns to be collapsed.
  #
  # @sig (*(String | Pathname | Array[String | Pathname])) -> void
  def collapse(*glob_patterns)
    glob_patterns = expand_paths(glob_patterns)
    mutex.synchronize do
      collapse_glob_patterns.merge(glob_patterns)
      collapse_dirs.merge(expand_glob_patterns(glob_patterns))
    end
  end

  # Configure a block to be called after setup and on each reload.
  # If setup was already done, the block runs immediately.
  #
  # @sig () { () -> void } -> void
  def on_setup(&block)
    mutex.synchronize do
      on_setup_callbacks << block
      block.call if @setup
    end
  end

  # Configure a block to be invoked once a certain constant path is loaded.
  # Supports multiple callbacks, and if there are many, they are executed in
  # the order in which they were defined.
  #
  #   loader.on_load("SomeApiClient") do |klass, _abspath|
  #     klass.endpoint = "https://api.dev"
  #   end
  #
  # Can also be configured for any constant loaded:
  #
  #   loader.on_load do |cpath, value, abspath|
  #     # ...
  #   end
  #
  # @raise [TypeError]
  # @sig (String) { (Object, String) -> void } -> void
  #      (:ANY) { (String, Object, String) -> void } -> void
  def on_load(cpath = :ANY, &block)
    raise TypeError, "on_load only accepts strings" unless cpath.is_a?(String) || cpath == :ANY

    mutex.synchronize do
      (on_load_callbacks[cpath] ||= []) << block
    end
  end

  # Configure a block to be invoked right before a certain constant is removed.
  # Supports multiple callbacks, and if there are many, they are executed in the
  # order in which they were defined.
  #
  #   loader.on_unload("Country") do |klass, _abspath|
  #     klass.clear_cache
  #   end
  #
  # Can also be configured for any removed constant:
  #
  #   loader.on_unload do |cpath, value, abspath|
  #     # ...
  #   end
  #
  # @raise [TypeError]
  # @sig (String) { (Object) -> void } -> void
  #      (:ANY) { (String, Object) -> void } -> void
  def on_unload(cpath = :ANY, &block)
    raise TypeError, "on_unload only accepts strings" unless cpath.is_a?(String) || cpath == :ANY

    mutex.synchronize do
      (on_unload_callbacks[cpath] ||= []) << block
    end
  end

  # Logs to `$stdout`, handy shortcut for debugging.
  #
  # @sig () -> void
  def log!
    @logger = ->(msg) { puts msg }
  end

  # Returns true if the argument has been configured to be ignored, or is a
  # descendant of an ignored directory.
  #
  # @sig (String) -> bool
  internal def ignores?(abspath)
    # Common use case.
    return false if ignored_paths.empty?

    walk_up(abspath) do |path|
      return true  if ignored_path?(path)
      return false if roots.key?(path)
    end

    false
  end

  # @sig (String) -> bool
  private def ignored_path?(abspath)
    ignored_paths.member?(abspath)
  end

  # @sig () -> Array[String]
  private def actual_roots
    roots.reject do |root_dir, _root_namespace|
      !dir?(root_dir) || ignored_path?(root_dir)
    end
  end

  # @sig (String) -> bool
  private def root_dir?(dir)
    roots.key?(dir)
  end

  # @sig (String) -> bool
  private def excluded_from_eager_load?(abspath)
    # Optimize this common use case.
    return false if eager_load_exclusions.empty?

    walk_up(abspath) do |path|
      return true  if eager_load_exclusions.member?(path)
      return false if roots.key?(path)
    end

    false
  end

  # @sig (String) -> bool
  private def collapse?(dir)
    collapse_dirs.member?(dir)
  end

  # @sig (String | Pathname | Array[String | Pathname]) -> Array[String]
  private def expand_paths(paths)
    paths.flatten.map! { |path| File.expand_path(path) }
  end

  # @sig (Array[String]) -> Array[String]
  private def expand_glob_patterns(glob_patterns)
    # Note that Dir.glob works with regular file names just fine. That is,
    # glob patterns technically need no wildcards.
    glob_patterns.flat_map { |glob_pattern| Dir.glob(glob_pattern) }
  end

  # @sig () -> void
  private def recompute_ignored_paths
    ignored_paths.replace(expand_glob_patterns(ignored_glob_patterns))
  end

  # @sig () -> void
  private def recompute_collapse_dirs
    collapse_dirs.replace(expand_glob_patterns(collapse_glob_patterns))
  end
end
