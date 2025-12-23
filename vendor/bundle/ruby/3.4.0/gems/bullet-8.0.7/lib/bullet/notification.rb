# frozen_string_literal: true

module Bullet
  module Notification
    autoload :Base, 'bullet/notification/base'
    autoload :UnusedEagerLoading, 'bullet/notification/unused_eager_loading'
    autoload :NPlusOneQuery, 'bullet/notification/n_plus_one_query'
    autoload :CounterCache, 'bullet/notification/counter_cache'

    class UnoptimizedQueryError < StandardError
    end
  end
end
