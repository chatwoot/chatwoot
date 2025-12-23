# frozen_string_literal: true

module Rack
  class MiniProfiler
    class ClientSettings

      COOKIE_NAME = "__profilin"

      BACKTRACE_DEFAULT = nil
      BACKTRACE_FULL    = 1
      BACKTRACE_NONE    = 2

      attr_accessor :disable_profiling
      attr_accessor :backtrace_level

      def initialize(env, store, start)
        @request = ::Rack::Request.new(env)
        @cookie = @request.cookies[COOKIE_NAME]
        @store = store
        @start = start
        @backtrace_level = nil
        @orig_disable_profiling = @disable_profiling = nil

        @allowed_tokens, @orig_auth_tokens = nil

        if @cookie
          @cookie.split(",").map { |pair| pair.split("=") }.each do |k, v|
            @orig_disable_profiling = @disable_profiling = (v == 't') if k == "dp"
            @backtrace_level = v.to_i if k == "bt"
            @orig_auth_tokens = v.to_s.split("|") if k == "a"
          end
        end

        if !@backtrace_level.nil? && (@backtrace_level == 0 || @backtrace_level > BACKTRACE_NONE)
          @backtrace_level = nil
        end

        @orig_backtrace_level = @backtrace_level

      end

      def handle_cookie(result)
        status, headers, _body = result

        if (MiniProfiler.config.authorization_mode == :allow_authorized && !MiniProfiler.request_authorized?)
          # this is non-obvious, don't kill the profiling cookie on errors or short requests
          # this ensures that stuff that never reaches the rails stack does not kill profiling
          if status.to_i >= 200 && status.to_i < 300 && ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - @start) > 0.1)
            discard_cookie!(headers)
          end
        else
          write!(headers)
        end

        result
      end

      def write!(headers)

        tokens_changed = false

        if MiniProfiler.request_authorized? && MiniProfiler.config.authorization_mode == :allow_authorized
          @allowed_tokens ||= @store.allowed_tokens
          tokens_changed = !@orig_auth_tokens || ((@allowed_tokens - @orig_auth_tokens).length > 0)
        end

        if  @orig_disable_profiling != @disable_profiling ||
            @orig_backtrace_level != @backtrace_level ||
            @cookie.nil? ||
            tokens_changed

          settings = { "p" => "t" }
          settings["dp"] = "t"                  if @disable_profiling
          settings["bt"] = @backtrace_level     if @backtrace_level
          settings["a"] = @allowed_tokens.join("|") if @allowed_tokens && MiniProfiler.request_authorized?
          settings_string = settings.map { |k, v| "#{k}=#{v}" }.join(",")
          cookie = { value: settings_string, path: MiniProfiler.config.cookie_path, httponly: true }
          cookie[:secure] = true if @request.ssl?
          cookie[:same_site] = 'Lax'
          Rack::Utils.set_cookie_header!(headers, COOKIE_NAME, cookie)
        end
      end

      def discard_cookie!(headers)
        if @cookie
          Rack::Utils.delete_cookie_header!(headers, COOKIE_NAME, path: MiniProfiler.config.cookie_path)
        end
      end

      def has_valid_cookie?
        valid_cookie = !@cookie.nil?

        if (MiniProfiler.config.authorization_mode == :allow_authorized) && valid_cookie
          begin
            @allowed_tokens ||= @store.allowed_tokens
          rescue => e
            if MiniProfiler.config.storage_failure != nil
              MiniProfiler.config.storage_failure.call(e)
            end
          end

          valid_cookie = @allowed_tokens &&
            (Array === @orig_auth_tokens) &&
            ((@allowed_tokens & @orig_auth_tokens).length > 0)
        end

        valid_cookie
      end

      def disable_profiling?
        @disable_profiling
      end

      def backtrace_full?
        @backtrace_level == BACKTRACE_FULL
      end

      def backtrace_default?
        @backtrace_level == BACKTRACE_DEFAULT
      end

      def backtrace_none?
        @backtrace_level == BACKTRACE_NONE
      end
    end
  end
end
