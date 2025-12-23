# based on https://gist.github.com/mnutt/566725
module Searchkick
  module ControllerRuntime
    extend ActiveSupport::Concern

    protected

    attr_internal :searchkick_runtime

    def process_action(action, *args)
      # We also need to reset the runtime before each action
      # because of queries in middleware or in cases we are streaming
      # and it won't be cleaned up by the method below.
      Searchkick::LogSubscriber.reset_runtime
      super
    end

    def cleanup_view_runtime
      searchkick_rt_before_render = Searchkick::LogSubscriber.reset_runtime
      runtime = super
      searchkick_rt_after_render = Searchkick::LogSubscriber.reset_runtime
      self.searchkick_runtime = searchkick_rt_before_render + searchkick_rt_after_render
      runtime - searchkick_rt_after_render
    end

    def append_info_to_payload(payload)
      super
      payload[:searchkick_runtime] = (searchkick_runtime || 0) + Searchkick::LogSubscriber.reset_runtime
    end

    module ClassMethods
      def log_process_action(payload)
        messages = super
        runtime = payload[:searchkick_runtime]
        messages << ("Searchkick: %.1fms" % runtime.to_f) if runtime.to_f > 0
        messages
      end
    end
  end
end
