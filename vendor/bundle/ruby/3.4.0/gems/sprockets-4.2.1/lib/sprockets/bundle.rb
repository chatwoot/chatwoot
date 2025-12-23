# frozen_string_literal: true
require 'set'
require 'sprockets/utils'
require 'sprockets/uri_utils'

module Sprockets
  # Internal: Bundle processor takes a single file asset and prepends all the
  # `:required` URIs to the contents.
  #
  # Uses pipeline metadata:
  #
  #   :required - Ordered Set of asset URIs to prepend
  #   :stubbed  - Set of asset URIs to subtract from the required set.
  #
  # Also see DirectiveProcessor.
  class Bundle
    def self.call(input)
      env  = input[:environment]
      type = input[:content_type]
      input[:links] ||= Set.new
      dependencies = Set.new(input[:metadata][:dependencies])

      processed_uri, deps = env.resolve(input[:filename], accept: type, pipeline: :self)
      dependencies.merge(deps)

      # DirectiveProcessor (and any other transformers called here with pipeline=self)
      primary_asset = env.load(processed_uri)
      to_load = primary_asset.metadata.delete(:to_load) || Set.new
      to_link = primary_asset.metadata.delete(:to_link) || Set.new

      to_load.each do |uri|
        loaded_asset = env.load(uri)
        dependencies.merge(loaded_asset.metadata[:dependencies])
        if to_link.include?(uri)
          primary_metadata = primary_asset.metadata
          input[:links]            << loaded_asset.uri
          primary_metadata[:links] << loaded_asset.uri
        end
      end

      find_required = proc { |uri| env.load(uri).metadata[:required] }
      required = Utils.dfs(processed_uri, &find_required)
      stubbed  = Utils.dfs(env.load(processed_uri).metadata[:stubbed], &find_required)
      required.subtract(stubbed)
      dedup(required)
      assets = required.map { |uri| env.load(uri) }

      (required + stubbed).each do |uri|
        dependencies.merge(env.load(uri).metadata[:dependencies])
      end

      reducers = Hash[env.match_mime_type_keys(env.config[:bundle_reducers], type).flat_map(&:to_a)]
      process_bundle_reducers(input, assets, reducers).merge(dependencies: dependencies, included: assets.map(&:uri))
    end

    # Internal: Removes uri from required if it's already included as an alias.
    #
    # required - Set of required uris
    #
    # Returns deduped set of uris
    def self.dedup(required)
      dupes = required.reduce([]) do |r, uri|
        path, params = URIUtils.parse_asset_uri(uri)
        if (params.delete(:index_alias))
          r << URIUtils.build_asset_uri(path, params)
        end
        r
      end
      required.subtract(dupes)
    end

    # Internal: Run bundle reducers on set of Assets producing a reduced
    # metadata Hash.
    #
    # filename - String bundle filename
    # assets - Array of Assets
    # reducers - Array of [initial, reducer_proc] pairs
    #
    # Returns reduced asset metadata Hash.
    def self.process_bundle_reducers(input, assets, reducers)
      initial = {}
      reducers.each do |k, (v, _)|
        if v.respond_to?(:call)
          initial[k] = v.call(input)
        elsif !v.nil?
          initial[k] = v
        end
      end

      assets.reduce(initial) do |h, asset|
        reducers.each do |k, (_, block)|
          value = k == :data ? asset.source : asset.metadata[k]
          if h.key?(k)
            if !value.nil?
              h[k] = block.call(h[k], value)
            end
          else
            h[k] = value
          end
        end
        h
      end
    end
  end
end
