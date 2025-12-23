# frozen_string_literal: true
module Rack
  class MiniProfiler
    module Views
      def resources_root
        @resources_root ||= ::File.expand_path("../../html", __FILE__)
      end

      def share_template
        @share_template ||= ERB.new(::File.read(::File.expand_path("../html/share.html", ::File.dirname(__FILE__))))
      end

      def generate_html(page_struct, env, result_json = page_struct.to_json)
        # double-assigning to suppress "assigned but unused variable" warnings
        path = path = "#{env['RACK_MINI_PROFILER_ORIGINAL_SCRIPT_NAME']}#{@config.base_url_path}"
        version = version = MiniProfiler::ASSET_VERSION
        json = json = result_json
        includes = includes = get_profile_script(env)
        name = name = page_struct[:name]
        duration = duration = page_struct.duration_ms.round(1).to_s

        share_template.result(binding)
      end

      # get_profile_script returns script to be injected inside current html page
      # By default, profile_script is appended to the end of all html requests automatically.
      # Calling get_profile_script cancels automatic append for the current page
      # Use it when:
      # * you have disabled auto append behaviour throught :auto_inject => false flag
      # * you do not want script to be automatically appended for the current page. You can also call cancel_auto_inject
      def get_profile_script(env)
        path = public_base_path(env)
        version = MiniProfiler::ASSET_VERSION
        if @config.assets_url
          url = @config.assets_url.call('rack-mini-profiler.js', version, env)
          css_url = @config.assets_url.call('rack-mini-profiler.css', version, env)
        end

        url = "#{path}includes.js?v=#{version}" if !url
        css_url = "#{path}includes.css?v=#{version}" if !css_url

        content_security_policy_nonce = @config.content_security_policy_nonce ||
                                        env["action_dispatch.content_security_policy_nonce"] ||
                                        env["secure_headers_content_security_policy_nonce"]

        settings = {
         path: path,
         url: url,
         cssUrl: css_url,
         version: version,
         verticalPosition: @config.vertical_position,
         horizontalPosition: @config.horizontal_position,
         showTrivial: @config.show_trivial,
         showChildren: @config.show_children,
         maxTracesToShow: @config.max_traces_to_show,
         showControls: @config.show_controls,
         showTotalSqlCount: @config.show_total_sql_count,
         authorized: true,
         toggleShortcut: @config.toggle_shortcut,
         startHidden: @config.start_hidden,
         collapseResults: @config.collapse_results,
         htmlContainer: @config.html_container,
         hiddenCustomFields: @config.snapshot_hidden_custom_fields.join(','),
         cspNonce: content_security_policy_nonce,
         hotwireTurboDriveSupport: @config.enable_hotwire_turbo_drive_support,
        }

        if current && current.page_struct
          settings[:ids]       = ids_comma_separated(env)
          settings[:currentId] = current.page_struct[:id]
        else
          settings[:ids]       = []
          settings[:currentId] = ""
        end

        # TODO : cache this snippet
        script = ::File.read(::File.expand_path('../html/profile_handler.js', ::File.dirname(__FILE__)))
        # replace the variables
        settings.each do |k, v|
          regex = Regexp.new("\\{#{k.to_s}\\}")
          script.gsub!(regex, v.to_s)
        end

        current.inject_js = false if current
        script
      end

      BLANK_PAGE = <<~HTML
        <!DOCTYPE html>
        <html>
          <head>
            <title>Rack::MiniProfiler Requests</title>
          </head>
          <body>
          </body>
        </html>
      HTML
      def blank_page_html
        BLANK_PAGE
      end

      def make_link(postfix, env)
        link = env["PATH_INFO"] + "?" + env["QUERY_STRING"].sub("#{@config.profile_parameter}=help", "#{@config.profile_parameter}=#{postfix}")
        "#{@config.profile_parameter}=<a href='#{ERB::Util.html_escape(link)}'>#{postfix}</a>"
      end

      def flamegraph(graph, path, env)
        headers = { 'Content-Type' => 'text/html' }
        iframe_src = "#{public_base_path(env)}speedscope/index.html"
        html = <<~HTML
          <!DOCTYPE html>
          <html>
            <head>
              <title>Rack::MiniProfiler Flamegraph</title>
              <style>
                body { margin: 0; height: 100vh; }
                #speedscope-iframe { width: 100%; height: 100%; border: none; }
              </style>
            </head>
            <body>
              <script type="text/javascript">
                var graph = #{JSON.generate(graph)};
                var json = JSON.stringify(graph);
                var blob = new Blob([json], { type: 'text/plain' });
                var objUrl = encodeURIComponent(URL.createObjectURL(blob));
                var iframe = document.createElement('IFRAME');
                iframe.setAttribute('id', 'speedscope-iframe');
                document.body.appendChild(iframe);
                var iframeUrl = '#{iframe_src}#profileURL=' + objUrl + '&title=' + 'Flamegraph for #{CGI.escape(path)}';
                iframe.setAttribute('src', iframeUrl);
              </script>
            </body>
          </html>
        HTML
        [200, headers, [html]]
      end

      def help(client_settings, env)
        headers = { 'Content-Type' => 'text/html' }
        html = <<~HTML
          <!DOCTYPE html>
          <html>
            <head>
              <title>Rack::MiniProfiler Help</title>
            </head>
            <body>
              <pre style='line-height: 30px; font-size: 16px'>
                This is the help menu of the <a href='#{Rack::MiniProfiler::SOURCE_CODE_URI}'>rack-mini-profiler</a> gem, append the following to your query string for more options:

                #{make_link "help", env} : display this screen
                #{make_link "env", env} : display the rack environment
                #{make_link "skip", env} : skip mini profiler for this request
                #{make_link "no-backtrace", env} #{"(*) " if client_settings.backtrace_none?}: don't collect stack traces from all the SQL executed (sticky, use #{@config.profile_parameter}=normal-backtrace to enable)
                #{make_link "normal-backtrace", env} #{"(*) " if client_settings.backtrace_default?}: collect stack traces from all the SQL executed and filter normally
                #{make_link "full-backtrace", env} #{"(*) " if client_settings.backtrace_full?}: enable full backtraces for SQL executed (use #{@config.profile_parameter}=normal-backtrace to disable)
                #{make_link "disable", env} : disable profiling for this session
                #{make_link "enable", env} : enable profiling for this session (if previously disabled)
                #{make_link "profile-gc", env} : perform gc profiling on this request, analyzes ObjectSpace generated by request
                #{make_link "profile-memory", env} : requires the memory_profiler gem, new location based report
                #{make_link "flamegraph", env} : a graph representing sampled activity (requires the stackprof gem).
                #{make_link "async-flamegraph", env} : store flamegraph data for this page and all its AJAX requests. Flamegraph links will be available in the mini-profiler UI (requires the stackprof gem).
                #{make_link "flamegraph&flamegraph_sample_rate=1", env}: creates a flamegraph with the specified sample rate (in ms). Overrides value set in config
                #{make_link "flamegraph&flamegraph_mode=cpu", env}: creates a flamegraph with the specified mode (one of cpu, wall, object, or custom). Overrides value set in config
                #{make_link "flamegraph_embed", env} : a graph representing sampled activity (requires the stackprof gem), embedded resources for use on an intranet.
                #{make_link "trace-exceptions", env} : will return all the spots where your application raises exceptions
                #{make_link "analyze-memory", env} : will perform basic memory analysis of heap

                All features can also be accessed by adding the X-Rack-Mini-Profiler header to the request, with any of the values above (e.g. 'X-Rack-Mini-Profiler: flamegraph')
              </pre>
            </body>
          </html>
        HTML

        [200, headers, [html]]
      end

      def url_for_snapshots_group(group_name)
        qs = Rack::Utils.build_query({ group_name: group_name })
        "/#{@config.base_url_path.gsub('/', '')}/snapshots?#{qs}"
      end

      def url_for_snapshot(id, group_name)
        qs = Rack::Utils.build_query({ id: id, group: group_name })
        "/#{@config.base_url_path.gsub('/', '')}/results?#{qs}"
      end

      def public_base_path(env)
        "#{env['RACK_MINI_PROFILER_ORIGINAL_SCRIPT_NAME']}#{@config.base_url_path}"
      end
    end
  end
end
