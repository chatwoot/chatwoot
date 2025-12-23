# frozen_string_literal: true

if ENV['RACK_MINI_PROFILER_PATCH_NET_HTTP'] != 'false'
  if (defined?(Net) && defined?(Net::HTTP))
    if defined?(Rack::MINI_PROFILER_PREPEND_NET_HTTP_PATCH)
      module NetHTTPWithMiniProfiler
        def request(request, *args, &block)
          Rack::MiniProfiler.step("Net::HTTP #{request.method} #{request.path}") do
            super
          end
        end
      end
      Net::HTTP.prepend(NetHTTPWithMiniProfiler)
    else
      Net::HTTP.class_eval do
        def request_with_mini_profiler(*args, &block)
          request = args[0]
          Rack::MiniProfiler.step("Net::HTTP #{request.method} #{request.path}") do
            request_without_mini_profiler(*args, &block)
          end
        end
        alias request_without_mini_profiler request
        alias request request_with_mini_profiler
      end
    end
  end
end
