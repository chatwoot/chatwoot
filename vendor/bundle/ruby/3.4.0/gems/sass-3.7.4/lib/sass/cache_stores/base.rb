module Sass
  module CacheStores
    # An abstract base class for backends for the Sass cache.
    # Any key-value store can act as such a backend;
    # it just needs to implement the
    # \{#_store} and \{#_retrieve} methods.
    #
    # To use a cache store with Sass,
    # use the {file:SASS_REFERENCE.md#cache_store-option `:cache_store` option}.
    #
    # @abstract
    class Base
      # Store cached contents for later retrieval
      # Must be implemented by all CacheStore subclasses
      #
      # Note: cache contents contain binary data.
      #
      # @param key [String] The key to store the contents under
      # @param version [String] The current sass version.
      #                Cached contents must not be retrieved across different versions of sass.
      # @param sha [String] The sha of the sass source.
      #                Cached contents must not be retrieved if the sha has changed.
      # @param contents [String] The contents to store.
      def _store(key, version, sha, contents)
        raise "#{self.class} must implement #_store."
      end

      # Retrieved cached contents.
      # Must be implemented by all subclasses.
      #
      # Note: if the key exists but the sha or version have changed,
      # then the key may be deleted by the cache store, if it wants to do so.
      #
      # @param key [String] The key to retrieve
      # @param version [String] The current sass version.
      #                Cached contents must not be retrieved across different versions of sass.
      # @param sha [String] The sha of the sass source.
      #                Cached contents must not be retrieved if the sha has changed.
      # @return [String] The contents that were previously stored.
      # @return [NilClass] when the cache key is not found or the version or sha have changed.
      def _retrieve(key, version, sha)
        raise "#{self.class} must implement #_retrieve."
      end

      # Store a {Sass::Tree::RootNode}.
      #
      # @param key [String] The key to store it under.
      # @param sha [String] The checksum for the contents that are being stored.
      # @param root [Object] The root node to cache.
      def store(key, sha, root)
        _store(key, Sass::VERSION, sha, Marshal.dump(root))
      rescue TypeError, LoadError => e
        Sass::Util.sass_warn "Warning. Error encountered while saving cache #{path_to(key)}: #{e}"
        nil
      end

      # Retrieve a {Sass::Tree::RootNode}.
      #
      # @param key [String] The key the root element was stored under.
      # @param sha [String] The checksum of the root element's content.
      # @return [Object] The cached object.
      def retrieve(key, sha)
        contents = _retrieve(key, Sass::VERSION, sha)
        Marshal.load(contents) if contents
      rescue EOFError, TypeError, ArgumentError, LoadError => e
        Sass::Util.sass_warn "Warning. Error encountered while reading cache #{path_to(key)}: #{e}"
        nil
      end

      # Return the key for the sass file.
      #
      # The `(sass_dirname, sass_basename)` pair
      # should uniquely identify the Sass document,
      # but otherwise there are no restrictions on their content.
      #
      # @param sass_dirname [String]
      #   The fully-expanded location of the Sass file.
      #   This corresponds to the directory name on a filesystem.
      # @param sass_basename [String] The name of the Sass file that is being referenced.
      #   This corresponds to the basename on a filesystem.
      def key(sass_dirname, sass_basename)
        dir = Digest::SHA1.hexdigest(sass_dirname)
        filename = "#{sass_basename}c"
        "#{dir}/#{filename}"
      end
    end
  end
end
