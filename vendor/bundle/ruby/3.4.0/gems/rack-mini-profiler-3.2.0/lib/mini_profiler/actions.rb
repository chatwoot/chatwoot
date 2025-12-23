# frozen_string_literal: true
module Rack
  class MiniProfiler
    module Actions
      def serve_snapshot(env)
        MiniProfiler.authorize_request
        status = 200
        headers = { 'Content-Type' => 'text/html' }
        qp = Rack::Utils.parse_nested_query(env['QUERY_STRING'])
        if group_name = qp["group_name"]
          list = @storage.snapshots_group(group_name)
          list.each do |snapshot|
            snapshot[:url] = url_for_snapshot(snapshot[:id], group_name)
          end
          data = {
            group_name: group_name,
            list: list
          }
        else
          list = @storage.snapshots_overview
          list.each do |group|
            group[:url] = url_for_snapshots_group(group[:name])
          end
          data = {
            page: "overview",
            list: list
          }
        end
        data_html = <<~HTML
          <div style="display: none;" id="snapshots-data">
          #{data.to_json}
          </div>
        HTML
        response = Rack::Response.new([], status, headers)

        response.write <<~HTML
          <!DOCTYPE html>
          <html>
            <head>
              <title>Rack::MiniProfiler Snapshots</title>
            </head>
            <body class="mp-snapshots">
        HTML
        response.write(data_html)
        script = self.get_profile_script(env)
        response.write(script)
        response.write <<~HTML
            </body>
          </html>
        HTML
        response.finish
      end

      def serve_file(env, file_name:)
        resources_env = env.dup
        resources_env['PATH_INFO'] = file_name

        rack_file = Rack::File.new(resources_root, 'Cache-Control' => "max-age=#{cache_control_value}")
        rack_file.call(resources_env)
      end

      def serve_results(env)
        request     = Rack::Request.new(env)
        id          = request.params['id']
        group_name  = request.params['group']
        is_snapshot = group_name && group_name.size > 0
        if is_snapshot
          page_struct = @storage.load_snapshot(id, group_name)
        else
          page_struct = @storage.load(id)
        end
        if !page_struct && is_snapshot
          id = ERB::Util.html_escape(id)
          return [404, {}, ["Snapshot with id '#{id}' not found"]]
        elsif !page_struct
          @storage.set_viewed(user(env), id)
          id        = ERB::Util.html_escape(id)
          user_info = ERB::Util.html_escape(user(env))
          return [404, {}, ["Request not found: #{id} - user #{user_info}"]]
        end
        if !page_struct[:has_user_viewed] && !is_snapshot
          page_struct[:client_timings]  = TimerStruct::Client.init_from_form_data(env, page_struct)
          page_struct[:has_user_viewed] = true
          @storage.save(page_struct)
          @storage.set_viewed(user(env), id)
        end

        # If we're an XMLHttpRequest, serve up the contents as JSON
        if request.xhr?
          result_json = page_struct.to_json
          [200, { 'Content-Type' => 'application/json' }, [result_json]]
        else
          # Otherwise give the HTML back
          html = generate_html(page_struct, env)
          [200, { 'Content-Type' => 'text/html' }, [html]]
        end
      end

      def serve_flamegraph(env)
        request     = Rack::Request.new(env)
        id          = request.params['id']
        page_struct = @storage.load(id)

        if !page_struct
          id        = ERB::Util.html_escape(id)
          user_info = ERB::Util.html_escape(user(env))
          return [404, {}, ["Request not found: #{id} - user #{user_info}"]]
        end

        if !page_struct[:flamegraph]
          return [404, {}, ["No flamegraph available for #{ERB::Util.html_escape(id)}"]]
        end

        self.flamegraph(page_struct[:flamegraph], page_struct[:request_path], env)
      end

      def serve_profile_gc(env, client_settings)
        return tool_disabled_message(client_settings) if !advanced_debugging_enabled?

        client_settings.handle_cookie(Rack::MiniProfiler::GCProfiler.new.profile_gc(@app, env))
      end

      def serve_profile_memory(env, client_settings)
        return tool_disabled_message(client_settings) if !advanced_debugging_enabled?

        unless defined?(MemoryProfiler) && MemoryProfiler.respond_to?(:report)
          message = "Please install the memory_profiler gem and require it: add gem 'memory_profiler' to your Gemfile"
          status, headers, body = @app.call(env)
          body.close if body.respond_to? :close

          return client_settings.handle_cookie(
            text_result(message, status: 500, headers: headers)
          )
        end

        query_params = Rack::Utils.parse_nested_query(query_string)
        options = {
          ignore_files: query_params['memory_profiler_ignore_files'],
          allow_files: query_params['memory_profiler_allow_files'],
        }
        options[:top] = Integer(query_params['memory_profiler_top']) if query_params.key?('memory_profiler_top')
        result = StringIO.new
        report = MemoryProfiler.report(options) do
          _, _, body = @app.call(env)
          body.close if body.respond_to? :close
        end
        report.pretty_print(result)
        client_settings.handle_cookie(text_result(result.string))
      end
    end
  end
end
