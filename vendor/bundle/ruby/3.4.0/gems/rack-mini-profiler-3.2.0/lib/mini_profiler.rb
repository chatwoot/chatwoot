# frozen_string_literal: true

require 'cgi'
require 'json'
require 'erb'

require 'mini_profiler/timer_struct'
require 'mini_profiler/storage'
require 'mini_profiler/config'
require 'mini_profiler/profiling_methods'
require 'mini_profiler/context'
require 'mini_profiler/client_settings'
require 'mini_profiler/gc_profiler'
require 'mini_profiler/snapshots_transporter'
require 'mini_profiler/views'
require 'mini_profiler/actions'

module Rack
  class MiniProfiler
    include Actions
    include Views

    class << self
      include Rack::MiniProfiler::ProfilingMethods
      attr_accessor :subscribe_sql_active_record

      def patch_rails?
        !!defined?(Rack::MINI_PROFILER_ENABLE_RAILS_PATCHES)
      end

      def generate_id
        rand(36**20).to_s(36)
      end

      def reset_config
        @config = Config.default
      end

      # So we can change the configuration if we want
      def config
        @config ||= Config.default
      end

      def current
        Thread.current[:mini_profiler_private]
      end

      def current=(c)
        # we use TLS cause we need access to this from sql blocks and code blocks that have no access to env
        Thread.current[:mini_profiler_snapshot_custom_fields] = nil
        Thread.current[:mp_ongoing_snapshot] = nil
        Thread.current[:mini_profiler_private] = c
      end

      def add_snapshot_custom_field(key, value)
        thread_var_key = :mini_profiler_snapshot_custom_fields
        Thread.current[thread_var_key] ||= {}
        Thread.current[thread_var_key][key] = value
      end

      def get_snapshot_custom_fields
        Thread.current[:mini_profiler_snapshot_custom_fields]
      end

      # discard existing results, don't track this request
      def discard_results
        self.current.discard = true if current
      end

      def create_current(env = {}, options = {})
        # profiling the request
        context               = Context.new
        context.inject_js     = config.auto_inject && (!env['HTTP_X_REQUESTED_WITH'].eql? 'XMLHttpRequest')
        context.page_struct   = TimerStruct::Page.new(env)
        context.current_timer = context.page_struct[:root]
        self.current          = context
      end

      def authorize_request
        Thread.current[:mp_authorized] = true
      end

      def deauthorize_request
        Thread.current[:mp_authorized] = nil
      end

      def request_authorized?
        Thread.current[:mp_authorized]
      end

      def advanced_tools_message
        <<~TEXT
          This feature is disabled by default, to enable set the enable_advanced_debugging_tools option to true in Mini Profiler config.
        TEXT
      end

      def binds_to_params(binds)
        return if binds.nil? || config.max_sql_param_length == 0
        # map ActiveRecord::Relation::QueryAttribute to [name, value]
        params = binds.map { |c| c.kind_of?(Array) ? [c.first, c.last] : [c.name, c.value] }
        if (skip = config.skip_sql_param_names)
          params.map { |(n, v)| n =~ skip ? [n, nil] : [n, v] }
        else
          params
        end
      end

      def snapshots_transporter?
        !!config.snapshots_transport_destination_url &&
        !!config.snapshots_transport_auth_key
      end

      def redact_sql_queries?
        Thread.current[:mp_ongoing_snapshot] == true &&
        Rack::MiniProfiler.config.snapshots_redact_sql_queries
      end
    end

    #
    # options:
    # :auto_inject - should script be automatically injected on every html page (not xhr)
    def initialize(app, config = nil)
      MiniProfiler.config.merge!(config)
      @config = MiniProfiler.config
      @app    = app
      @config.base_url_path += "/" unless @config.base_url_path.end_with? "/"
      unless @config.storage_instance
        @config.storage_instance = @config.storage.new(@config.storage_options)
      end
      @storage = @config.storage_instance
    end

    def user(env)
      @config.user_provider.call(env)
    end

    def current
      MiniProfiler.current
    end

    def current=(c)
      MiniProfiler.current = c
    end

    def config
      @config
    end

    def advanced_debugging_enabled?
      config.enable_advanced_debugging_tools
    end

    def tool_disabled_message(client_settings)
      client_settings.handle_cookie(text_result(Rack::MiniProfiler.advanced_tools_message))
    end

    def call(env)
      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      client_settings = ClientSettings.new(env, @storage, start)
      MiniProfiler.deauthorize_request if @config.authorization_mode == :allow_authorized

      status = headers = body = nil
      path         = env['PATH_INFO'].sub('//', '/')

      # Someone (e.g. Rails engine) could change the SCRIPT_NAME so we save it
      env['RACK_MINI_PROFILER_ORIGINAL_SCRIPT_NAME'] = ENV['PASSENGER_BASE_URI'] || env['SCRIPT_NAME']

      skip_it = matches_action?('skip', env) || (
        @config.skip_paths &&
        @config.skip_paths.any? do |p|
          if p.instance_of?(String)
            path.start_with?(p)
          elsif p.instance_of?(Regexp)
            p.match?(path)
          end
        end
      )
      if skip_it
        return client_settings.handle_cookie(@app.call(env))
      end

      skip_it = (@config.pre_authorize_cb && !@config.pre_authorize_cb.call(env))

      if skip_it || (
        @config.authorization_mode == :allow_authorized &&
        !client_settings.has_valid_cookie?
      )
        if take_snapshot?(path)
          return client_settings.handle_cookie(take_snapshot(env, start))
        else
          return client_settings.handle_cookie(@app.call(env))
        end
      end

      # handle all /mini-profiler requests here
      if path.start_with? @config.base_url_path
        file_name = path.sub(@config.base_url_path, '')

        case file_name
        when 'results'
          return serve_results(env)
        when 'snapshots'
          self.current = nil
          return serve_snapshot(env)
        when 'flamegraph'
          return serve_flamegraph(env)
        end

        return client_settings.handle_cookie(serve_file(env, file_name: file_name))
      end

      has_disable_cookie = client_settings.disable_profiling?
      # manual session disable / enable
      if matches_action?('disable', env) || has_disable_cookie
        skip_it = true
      end

      if matches_action?('enable', env)
        skip_it = false
        config.enabled = true
      end

      if skip_it || !config.enabled
        status, headers, body = @app.call(env)
        client_settings.disable_profiling = true
        return client_settings.handle_cookie([status, headers, body])
      end

      # remember that profiling is not disabled (ie enabled)
      client_settings.disable_profiling = false

      # profile gc
      if matches_action?('profile-gc', env)
        current.measure = false if current
        return serve_profile_gc(env, client_settings)
      end

      # profile memory
      if matches_action?('profile-memory', env)
        return serve_profile_memory(env, client_settings)
      end

      # any other requests past this point are going to the app to be profiled

      MiniProfiler.create_current(env, @config)

      if matches_action?('normal-backtrace', env)
        client_settings.backtrace_level = ClientSettings::BACKTRACE_DEFAULT
      elsif matches_action?('no-backtrace', env)
        current.skip_backtrace = true
        client_settings.backtrace_level = ClientSettings::BACKTRACE_NONE
      elsif matches_action?('full-backtrace', env) || client_settings.backtrace_full?
        current.full_backtrace = true
        client_settings.backtrace_level = ClientSettings::BACKTRACE_FULL
      elsif client_settings.backtrace_none?
        current.skip_backtrace = true
      end

      flamegraph = nil

      trace_exceptions = matches_action?('trace-exceptions', env) && defined? TracePoint
      status, headers, body, exceptions, trace = nil

      if trace_exceptions
        exceptions = []
        trace      = TracePoint.new(:raise) do |tp|
          exceptions << tp.raised_exception
        end
        trace.enable
      end

      begin

        # Strip all the caching headers so we don't get 304s back
        #  This solves a very annoying bug where rack mini profiler never shows up
        if config.disable_caching
          env['HTTP_IF_MODIFIED_SINCE'] = ''
          env['HTTP_IF_NONE_MATCH']     = ''
        end

        orig_accept_encoding = env['HTTP_ACCEPT_ENCODING']
        # Prevent response body from being compressed
        env['HTTP_ACCEPT_ENCODING'] = 'identity' if config.suppress_encoding

        if matches_action?('flamegraph', env) || matches_action?('async-flamegraph', env) || env['HTTP_REFERER'] =~ /pp=async-flamegraph/
          if defined?(StackProf) && StackProf.respond_to?(:run)
            # do not sully our profile with mini profiler timings
            current.measure = false
            match_data      = action_parameters(env)['flamegraph_sample_rate']

            if match_data && !match_data[1].to_f.zero?
              sample_rate = match_data[1].to_f
            else
              sample_rate = config.flamegraph_sample_rate
            end

            mode_match_data = action_parameters(env)['flamegraph_mode']

            if mode_match_data && [:cpu, :wall, :object, :custom].include?(mode_match_data[1].to_sym)
              mode = mode_match_data[1].to_sym
            else
              mode = config.flamegraph_mode
            end

            flamegraph = StackProf.run(
              mode: mode,
              raw: true,
              aggregate: false,
              interval: (sample_rate * 1000).to_i
            ) do
              status, headers, body = @app.call(env)
            end
          else
            message = "Please install the stackprof gem and require it: add gem 'stackprof' to your Gemfile"
            status, headers, body = @app.call(env)
            body.close if body.respond_to? :close

            return client_settings.handle_cookie(
              text_result(message, status: status, headers: headers)
            )
          end
        elsif path == '/rack-mini-profiler/requests'
          status, headers, body = [200, { 'Content-Type' => 'text/html' }, [blank_page_html]]
        else
          status, headers, body = @app.call(env)
        end
      ensure
        trace.disable if trace
        env['HTTP_ACCEPT_ENCODING'] = orig_accept_encoding if config.suppress_encoding
      end

      skip_it = current.discard

      if (config.authorization_mode == :allow_authorized && !MiniProfiler.request_authorized?)
        skip_it = true
      end

      return client_settings.handle_cookie([status, headers, body]) if skip_it

      # we must do this here, otherwise current[:discard] is not being properly treated
      if trace_exceptions
        body.close if body.respond_to? :close

        query_params = action_parameters(env)
        trace_exceptions_filter = query_params['trace_exceptions_filter']
        if trace_exceptions_filter
          trace_exceptions_regex = Regexp.new(trace_exceptions_filter)
          exceptions.reject! { |ex| ex.class.name =~ trace_exceptions_regex }
        end

        return client_settings.handle_cookie(dump_exceptions exceptions)
      end

      if matches_action?("env", env)
        return tool_disabled_message(client_settings) if !advanced_debugging_enabled?
        body.close if body.respond_to? :close
        return client_settings.handle_cookie(dump_env env)
      end

      if matches_action?("analyze-memory", env)
        return tool_disabled_message(client_settings) if !advanced_debugging_enabled?
        body.close if body.respond_to? :close
        return client_settings.handle_cookie(analyze_memory)
      end

      if matches_action?("help", env)
        body.close if body.respond_to? :close
        return client_settings.handle_cookie(help(client_settings, env))
      end

      page_struct = current.page_struct
      page_struct[:user] = user(env)
      page_struct[:root].record_time((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000)

      if flamegraph && matches_action?("flamegraph", env)
        body.close if body.respond_to? :close
        return client_settings.handle_cookie(self.flamegraph(flamegraph, path, env))
      elsif flamegraph # async-flamegraph
        page_struct[:has_flamegraph] = true
        page_struct[:flamegraph] = flamegraph
      end

      begin
        @storage.save(page_struct)
        # no matter what it is, it should be unviewed, otherwise we will miss POST
        @storage.set_unviewed(page_struct[:user], page_struct[:id])

        # inject headers, script
        if status >= 200 && status < 300
          result = inject_profiler(env, status, headers, body)
          return client_settings.handle_cookie(result) if result
        end
      rescue Exception => e
        if @config.storage_failure != nil
          @config.storage_failure.call(e)
        end
      end

      client_settings.handle_cookie([status, headers, body])
    ensure
      # Make sure this always happens
      self.current = nil
    end

    def matches_action?(action, env)
      env['QUERY_STRING'] =~ /#{@config.profile_parameter}=#{action}/ ||
        env['HTTP_X_RACK_MINI_PROFILER'] == action
    end

    def action_parameters(env)
      query_params = Rack::Utils.parse_nested_query(env['QUERY_STRING'])
    end

    def inject_profiler(env, status, headers, body)
      # mini profiler is meddling with stuff, we can not cache cause we will get incorrect data
      # Rack::ETag has already inserted some nonesense in the chain
      content_type = headers['Content-Type']

      if config.disable_caching
        headers.delete('ETag')
        headers.delete('Date')
      end

      headers['X-MiniProfiler-Original-Cache-Control'] = headers['Cache-Control'] unless headers['Cache-Control'].nil?
      headers['Cache-Control'] = "#{"no-store, " if config.disable_caching}must-revalidate, private, max-age=0"

      # inject header
      if headers.is_a? Hash
        headers['X-MiniProfiler-Ids'] = ids_comma_separated(env)
      end

      if current.inject_js && content_type =~ /text\/html/
        response = Rack::Response.new([], status, headers)
        script   = self.get_profile_script(env)

        if String === body
          response.write inject(body, script)
        else
          body.each { |fragment| response.write inject(fragment, script) }
        end
        body.close if body.respond_to? :close
        response.finish
      else
        nil
      end
    end

    def inject(fragment, script)
      # find explicit or implicit body
      index = fragment.rindex(/<\/body>/i) || fragment.rindex(/<\/html>/i)
      if index
        # if for whatever crazy reason we dont get a utf string,
        #   just force the encoding, no utf in the mp scripts anyway
        if script.respond_to?(:encoding) && script.respond_to?(:force_encoding)
          script = script.force_encoding(fragment.encoding)
        end

        safe_script = script
        if script.respond_to?(:html_safe)
          safe_script = script.html_safe
        end

        fragment.insert(index, safe_script)
      else
        fragment
      end
    end

    def dump_exceptions(exceptions)
      body = "Exceptions raised during request\n\n".dup
      if exceptions.empty?
        body << "No exceptions raised"
      else
        body << "Exceptions: (#{exceptions.size} total)\n"
        exceptions.group_by(&:class).each do |klass, exceptions_per_class|
          body << "  #{klass.name} (#{exceptions_per_class.size})\n"
        end

        body << "\nBacktraces\n"
        exceptions.each_with_index do |e, i|
          body << "##{i + 1}: #{e.class} - \"#{e.message.lines.first.chomp}\"\n  #{e.backtrace.join("\n  ")}\n\n"
        end
      end
      text_result(body)
    end

    def dump_env(env)
      body = "Rack Environment\n---------------\n".dup
      env.each do |k, v|
        body << "#{k}: #{v}\n"
      end

      body << "\n\nEnvironment\n---------------\n"
      ENV.each do |k, v|
        body << "#{k}: #{v}\n"
      end

      body << "\n\nRuby Version\n---------------\n"
      body << "#{RUBY_VERSION} p#{RUBY_PATCHLEVEL}\n"

      body << "\n\nInternals\n---------------\n"
      body << "Storage Provider #{config.storage_instance}\n"
      body << "User #{user(env)}\n"
      body << config.storage_instance.diagnostics(user(env)) rescue "no diagnostics implemented for storage"

      text_result(body)
    end

    def trim_strings(strings, max_size)
      strings.sort! { |a, b| b[1] <=> a[1] }
      i = 0
      strings.delete_if { |_| (i += 1) > max_size }
    end

    def analyze_memory
      require 'objspace'

      utf8 = "utf-8"

      GC.start

      trunc = lambda do |str|
        str = str.length > 200 ? str : str[0..200]

        if str.encoding != Encoding::UTF_8
          str = str.dup
          str.force_encoding(utf8)

          unless str.valid_encoding?
            # work around bust string with a double conversion
            str.encode!("utf-16", "utf-8", invalid: :replace)
            str.encode!("utf-8", "utf-16")
          end
        end

        str
      end

      body = "ObjectSpace stats:\n\n".dup

      counts = ObjectSpace.count_objects
      total_strings = counts[:T_STRING]

      body << counts
        .sort { |a, b| b[1] <=> a[1] }
        .map { |k, v| "#{k}: #{v}" }
        .join("\n")

      strings = []
      string_counts = Hash.new(0)
      sample_strings = []

      max_size = 1000
      sample_every = total_strings / max_size

      i = 0
      ObjectSpace.each_object(String) do |str|
        i += 1
        string_counts[str] += 1
        strings << [trunc.call(str), str.length]
        sample_strings << [trunc.call(str), str.length] if i % sample_every == 0
        if strings.length > max_size * 2
          trim_strings(strings, max_size)
        end
      end

      trim_strings(strings, max_size)

      body << "\n\n\n1000 Largest strings:\n\n"
      body << strings.map { |s, len| "#{s[0..1000]}\n(len: #{len})\n\n" }.join("\n")

      body << "\n\n\n1000 Sample strings:\n\n"
      body << sample_strings.map { |s, len| "#{s[0..1000]}\n(len: #{len})\n\n" }.join("\n")

      body << "\n\n\n1000 Most common strings:\n\n"
      body << string_counts.sort { |a, b| b[1] <=> a[1] }[0..max_size].map { |s, len| "#{trunc.call(s)}\n(x #{len})\n\n" }.join("\n")

      text_result(body)
    end

    def text_result(body, status: 200, headers: nil)
      headers = (headers || {}).merge('Content-Type' => 'text/plain; charset=utf-8')
      [status, headers, [body]]
    end

    def ids(env)
      all = ([current.page_struct[:id]] + (@storage.get_unviewed_ids(user(env)) || [])).uniq
      if all.size > @config.max_traces_to_show
        all = all[0...@config.max_traces_to_show]
        @storage.set_all_unviewed(user(env), all)
      end
      all
    end

    def ids_comma_separated(env)
      ids(env).join(",")
    end

    # cancels automatic injection of profile script for the current page
    def cancel_auto_inject(env)
      current.inject_js = false
    end

    def cache_control_value
      86400
    end

    private

    def rails_route_from_path(path, method)
      if defined?(Rails) && defined?(ActionController::RoutingError)
        hash = Rails.application.routes.recognize_path(path, method: method)
        if hash && hash[:controller] && hash[:action]
          "#{hash[:controller]}##{hash[:action]}"
        end
      end
    rescue ActionController::RoutingError
      nil
    end

    def take_snapshot?(path)
      @config.snapshot_every_n_requests > 0 &&
      !path.start_with?(@config.base_url_path) &&
      @storage.should_take_snapshot?(@config.snapshot_every_n_requests)
    end

    def take_snapshot(env, start)
      MiniProfiler.create_current(env, @config)
      Thread.current[:mp_ongoing_snapshot] = true
      results = @app.call(env)
      status = results[0].to_i
      if status >= 200 && status < 300
        page_struct = current.page_struct
        page_struct[:root].record_time(
          (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000
        )
        custom_fields = MiniProfiler.get_snapshot_custom_fields
        page_struct[:custom_fields] = custom_fields if custom_fields
        if Rack::MiniProfiler.snapshots_transporter?
          Rack::MiniProfiler::SnapshotsTransporter.transport(page_struct)
        else
          group_name = rails_route_from_path(page_struct[:request_path], page_struct[:request_method])
          group_name ||= page_struct[:request_path]
          group_name = "#{page_struct[:request_method]} #{group_name}"
          @storage.push_snapshot(
            page_struct,
            group_name,
            @config
          )
        end
      end
      self.current = nil
      results
    end
  end
end
