# frozen_string_literal: true
require 'sprockets/asset'
require 'sprockets/digest_utils'
require 'sprockets/errors'
require 'sprockets/file_reader'
require 'sprockets/mime'
require 'sprockets/path_utils'
require 'sprockets/processing'
require 'sprockets/processor_utils'
require 'sprockets/resolve'
require 'sprockets/transformers'
require 'sprockets/uri_utils'
require 'sprockets/unloaded_asset'

module Sprockets

  # The loader phase takes a asset URI location and returns a constructed Asset
  # object.
  module Loader
    include DigestUtils, PathUtils, ProcessorUtils, URIUtils
    include Mime, Processing, Resolve, Transformers


    # Public: Load Asset by Asset URI.
    #
    # uri - A String containing complete URI to a file including schema
    #       and full path such as:
    #       "file:///Path/app/assets/js/app.js?type=application/javascript"
    #
    # Returns Asset.
    def load(uri)
      unloaded = UnloadedAsset.new(uri, self)
      if unloaded.params.key?(:id)
        unless asset = asset_from_cache(unloaded.asset_key)
          id = unloaded.params.delete(:id)
          uri_without_id = build_asset_uri(unloaded.filename, unloaded.params)
          asset = load_from_unloaded(UnloadedAsset.new(uri_without_id, self))
          if asset[:id] != id
            @logger.warn "Sprockets load error: Tried to find #{uri}, but latest was id #{asset[:id]}"
          end
        end
      else
        asset = fetch_asset_from_dependency_cache(unloaded) do |paths|
          # When asset is previously generated, its "dependencies" are stored in the cache.
          # The presence of `paths` indicates dependencies were stored.
          # We can check to see if the dependencies have not changed by "resolving" them and
          # generating a digest key from the resolved entries. If this digest key has not
          # changed, the asset will be pulled from cache.
          #
          # If this `paths` is present but the cache returns nothing then `fetch_asset_from_dependency_cache`
          # will confusingly be called again with `paths` set to nil where the asset will be
          # loaded from disk.
          if paths
            digest = DigestUtils.digest(resolve_dependencies(paths))
            if uri_from_cache = cache.get(unloaded.digest_key(digest), true)
              asset_from_cache(UnloadedAsset.new(uri_from_cache, self).asset_key)
            end
          else
            load_from_unloaded(unloaded)
          end
        end
      end
      Asset.new(asset)
    end

    private
      def compress_key_from_hash(hash, key)
        return unless hash.key?(key)
        value = hash[key].dup
        return if !value

        if block_given?
          value.map! do |x|
            if yield x
             compress_from_root(x)
            else
             x
            end
          end
        else
          value.map! { |x| compress_from_root(x) }
        end
        hash[key] = value
      end


      def expand_key_from_hash(hash, key)
        return unless hash.key?(key)
        value = hash[key].dup
        return if !value
        if block_given?
          value.map! do |x|
            if yield x
              expand_from_root(x)
            else
              x
            end
          end
        else
          value.map! { |x| expand_from_root(x) }
        end
        hash[key] = value
      end

      # Internal: Load asset hash from cache
      #
      # key - A String containing lookup information for an asset
      #
      # This method converts all "compressed" paths to absolute paths.
      # Returns a hash of values representing an asset
      def asset_from_cache(key)
        asset = cache.get(key, true)
        if asset
          asset[:uri]       = expand_from_root(asset[:uri])
          asset[:load_path] = expand_from_root(asset[:load_path])
          asset[:filename]  = expand_from_root(asset[:filename])
          expand_key_from_hash(asset[:metadata], :included)
          expand_key_from_hash(asset[:metadata], :links)
          expand_key_from_hash(asset[:metadata], :stubbed)
          expand_key_from_hash(asset[:metadata], :required)
          expand_key_from_hash(asset[:metadata], :to_load)
          expand_key_from_hash(asset[:metadata], :to_link)
          expand_key_from_hash(asset[:metadata], :dependencies) { |uri| uri.start_with?("file-digest://") }

          asset[:metadata].each_key do |k|
            next unless k.match?(/_dependencies\z/) # rubocop:disable Performance/EndWith
            expand_key_from_hash(asset[:metadata], k)
          end
        end
        asset
      end

      # Internal: Loads an asset and saves it to cache
      #
      # unloaded - An UnloadedAsset
      #
      # This method is only called when the given unloaded asset could not be
      # successfully pulled from cache.
      def load_from_unloaded(unloaded)
        unless file?(unloaded.filename)
          raise FileNotFound, "could not find file: #{unloaded.filename}"
        end

        path_to_split =
          if index_alias = unloaded.params[:index_alias]
            expand_from_root index_alias
          else
            unloaded.filename
          end

        load_path, logical_path = paths_split(config[:paths], path_to_split)

        unless load_path
          target = path_to_split
          target += " (index alias of #{unloaded.filename})" if unloaded.params[:index_alias]
          raise FileOutsidePaths, "#{target} is no longer under a load path: #{self.paths.join(', ')}"
        end

        extname, file_type = match_path_extname(logical_path, mime_exts)
        logical_path = logical_path.chomp(extname)
        name = logical_path

        if pipeline = unloaded.params[:pipeline]
          logical_path += ".#{pipeline}"
        end

        if type = unloaded.params[:type]
          extensions = config[:mime_types][type][:extensions]
          extension = extensions.include?(extname) ? extname : extensions.first
          logical_path += extension
        end

        if type != file_type && !config[:transformers][file_type][type]
          raise ConversionError, "could not convert #{file_type.inspect} to #{type.inspect}"
        end

        processors = processors_for(type, file_type, pipeline)

        processors_dep_uri = build_processors_uri(type, file_type, pipeline)
        dependencies = config[:dependencies] + [processors_dep_uri]

        # Read into memory and process if theres a processor pipeline
        if processors.any?
          result = call_processors(processors, {
            environment: self,
            cache: self.cache,
            uri: unloaded.uri,
            filename: unloaded.filename,
            load_path: load_path,
            name: name,
            content_type: type,
            metadata: {
              dependencies: dependencies
            }
          })
          validate_processor_result!(result)
          source = result.delete(:data)
          metadata = result
          metadata[:charset] = source.encoding.name.downcase unless metadata.key?(:charset)
          metadata[:digest]  = digest(source)
          metadata[:length]  = source.bytesize
          metadata[:environment_version] = version
        else
          dependencies << build_file_digest_uri(unloaded.filename)
          metadata = {
            digest: file_digest(unloaded.filename),
            length: self.stat(unloaded.filename).size,
            dependencies: dependencies,
            environment_version: version,
          }
        end

        asset = {
          uri: unloaded.uri,
          load_path: load_path,
          filename: unloaded.filename,
          name: name,
          logical_path: logical_path,
          content_type: type,
          source: source,
          metadata: metadata,
          dependencies_digest: DigestUtils.digest(resolve_dependencies(metadata[:dependencies]))
        }

        asset[:id]  = hexdigest(asset)
        asset[:uri] = build_asset_uri(unloaded.filename, unloaded.params.merge(id: asset[:id]))

        store_asset(asset, unloaded)
        asset
      end

      # Internal: Save a given asset to the cache
      #
      # asset - A hash containing values of loaded asset
      # unloaded - The UnloadedAsset used to lookup the `asset`
      #
      # This method converts all absolute paths to "compressed" paths
      # which are relative if they're in the root.
      def store_asset(asset, unloaded)
        # Save the asset in the cache under the new URI
        cached_asset             = asset.dup
        cached_asset[:uri]       = compress_from_root(asset[:uri])
        cached_asset[:filename]  = compress_from_root(asset[:filename])
        cached_asset[:load_path] = compress_from_root(asset[:load_path])

        if cached_asset[:metadata]
          # Deep dup to avoid modifying `asset`
          cached_asset[:metadata] = cached_asset[:metadata].dup
          compress_key_from_hash(cached_asset[:metadata], :included)
          compress_key_from_hash(cached_asset[:metadata], :links)
          compress_key_from_hash(cached_asset[:metadata], :stubbed)
          compress_key_from_hash(cached_asset[:metadata], :required)
          compress_key_from_hash(cached_asset[:metadata], :to_load)
          compress_key_from_hash(cached_asset[:metadata], :to_link)
          compress_key_from_hash(cached_asset[:metadata], :dependencies) { |uri| uri.start_with?("file-digest://") }

          cached_asset[:metadata].each do |key, value|
            next unless key.match?(/_dependencies\z/) # rubocop:disable Performance/EndWith
            compress_key_from_hash(cached_asset[:metadata], key)
          end
        end

        # Unloaded asset and stored_asset now have a different URI
        stored_asset = UnloadedAsset.new(asset[:uri], self)
        cache.set(stored_asset.asset_key, cached_asset, true)

        # Save the new relative path for the digest key of the unloaded asset
        cache.set(unloaded.digest_key(asset[:dependencies_digest]), stored_asset.compressed_path, true)
      end


      # Internal: Resolve set of dependency URIs.
      #
      # uris - An Array of "dependencies" for example:
      #        ["environment-version", "environment-paths", "processors:type=text/css&file_type=text/css",
      #           "file-digest:///Full/path/app/assets/stylesheets/application.css",
      #           "processors:type=text/css&file_type=text/css&pipeline=self",
      #           "file-digest:///Full/path/app/assets/stylesheets"]
      #
      # Returns back array of things that the given uri depends on
      # For example the environment version, if you're using a different version of sprockets
      # then the dependencies should be different, this is used only for generating cache key
      # for example the "environment-version" may be resolved to "environment-1.0-3.2.0" for
      # version "3.2.0" of sprockets.
      #
      # Any paths that are returned are converted to relative paths
      #
      # Returns array of resolved dependencies
      def resolve_dependencies(uris)
        uris.map { |uri| resolve_dependency(uri) }
      end

      # Internal: Retrieves an asset based on its digest
      #
      # unloaded - An UnloadedAsset
      # limit    - An Integer which sets the maximum number of versions of "histories"
      #            stored in the cache
      #
      # This method attempts to retrieve the last `limit` number of histories of an asset
      # from the cache a "history" which is an array of unresolved "dependencies" that the asset needs
      # to compile. In this case a dependency can refer to either an asset e.g. index.js
      # may rely on jquery.js (so jquery.js is a dependency), or other factors that may affect
      # compilation, such as the VERSION of Sprockets (i.e. the environment) and what "processors"
      # are used.
      #
      # For example a history array may look something like this
      #
      #   [["environment-version", "environment-paths", "processors:type=text/css&file_type=text/css",
      #     "file-digest:///Full/path/app/assets/stylesheets/application.css",
      #     "processors:type=text/css&file_digesttype=text/css&pipeline=self",
      #     "file-digest:///Full/path/app/assets/stylesheets"]]
      #
      # Where the first entry is a Set of dependencies for last generated version of that asset.
      # Multiple versions are stored since Sprockets keeps the last `limit` number of assets
      # generated present in the system.
      #
      # If a "history" of dependencies is present in the cache, each version of "history" will be
      # yielded to the passed block which is responsible for loading the asset. If found, the existing
      # history will be saved with the dependency that found a valid asset moved to the front.
      #
      # If no history is present, or if none of the histories could be resolved to a valid asset then,
      # the block is yielded to and expected to return a valid asset.
      # When this happens the dependencies for the returned asset are added to the "history", and older
      # entries are removed if the "history" is above `limit`.
      def fetch_asset_from_dependency_cache(unloaded, limit = 3)
        key = unloaded.dependency_history_key

        history = cache.get(key) || []
        history.each_with_index do |deps, index|
          expanded_deps = deps.map do |path|
            path.start_with?("file-digest://") ? expand_from_root(path) : path
          end
          if asset = yield(expanded_deps)
            cache.set(key, history.rotate!(index)) if index > 0
            return asset
          end
        end

        asset = yield
        deps  = asset[:metadata][:dependencies].dup.map! do |uri|
          uri.start_with?("file-digest://") ? compress_from_root(uri) : uri
        end
        cache.set(key, history.unshift(deps).take(limit))
        asset
      end
  end
end
