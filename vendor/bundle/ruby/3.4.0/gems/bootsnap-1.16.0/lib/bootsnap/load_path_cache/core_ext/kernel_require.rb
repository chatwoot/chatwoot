# frozen_string_literal: true

module Kernel
  module_function

  alias_method(:require_without_bootsnap, :require)

  def require(path)
    return require_without_bootsnap(path) unless Bootsnap::LoadPathCache.enabled?

    string_path = Bootsnap.rb_get_path(path)
    return false if Bootsnap::LoadPathCache.loaded_features_index.key?(string_path)

    resolved = Bootsnap::LoadPathCache.load_path_cache.find(string_path)
    if Bootsnap::LoadPathCache::FALLBACK_SCAN.equal?(resolved)
      if (cursor = Bootsnap::LoadPathCache.loaded_features_index.cursor(string_path))
        ret = require_without_bootsnap(path)
        resolved = Bootsnap::LoadPathCache.loaded_features_index.identify(string_path, cursor)
        Bootsnap::LoadPathCache.loaded_features_index.register(string_path, resolved)
        return ret
      else
        return require_without_bootsnap(path)
      end
    elsif false == resolved
      return false
    elsif resolved.nil?
      error = LoadError.new(+"cannot load such file -- #{path}")
      error.instance_variable_set(:@path, path)
      raise error
    else
      # Note that require registers to $LOADED_FEATURES while load does not.
      ret = require_without_bootsnap(resolved)
      Bootsnap::LoadPathCache.loaded_features_index.register(string_path, resolved)
      return ret
    end
  end
end
