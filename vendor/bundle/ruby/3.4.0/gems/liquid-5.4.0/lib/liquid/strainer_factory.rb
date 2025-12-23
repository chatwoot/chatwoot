# frozen_string_literal: true

module Liquid
  # StrainerFactory is the factory for the filters system.
  module StrainerFactory
    extend self

    def add_global_filter(filter)
      strainer_class_cache.clear
      GlobalCache.add_filter(filter)
    end

    def create(context, filters = [])
      strainer_from_cache(filters).new(context)
    end

    def global_filter_names
      GlobalCache.filter_method_names
    end

    GlobalCache = Class.new(StrainerTemplate)

    private

    def strainer_from_cache(filters)
      if filters.empty?
        GlobalCache
      else
        strainer_class_cache[filters] ||= begin
          klass = Class.new(GlobalCache)
          filters.each { |f| klass.add_filter(f) }
          klass
        end
      end
    end

    def strainer_class_cache
      @strainer_class_cache ||= {}
    end
  end
end
