# frozen_string_literal: true

module Bullet
  module Detector
    autoload :Base, 'bullet/detector/base'
    autoload :Association, 'bullet/detector/association'
    autoload :NPlusOneQuery, 'bullet/detector/n_plus_one_query'
    autoload :UnusedEagerLoading, 'bullet/detector/unused_eager_loading'
    autoload :CounterCache, 'bullet/detector/counter_cache'
  end
end
