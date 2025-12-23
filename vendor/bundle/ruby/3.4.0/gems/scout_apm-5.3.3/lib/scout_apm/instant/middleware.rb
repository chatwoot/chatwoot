# frozen_string_literal: false

module ScoutApm
  module Instant

    # an abstraction for manipulating the HTML we capture in the middleware
    class Page
      def initialize(html)
        @html = html

        if html.is_a?(Array)
          @html = html.inject("") { |memo, str| memo + str }
        end

        @to_add_to_head = []
        @to_add_to_body = []
      end

      def add_to_head(content)
        @to_add_to_head << content
      end

      def add_to_body(content)
        @to_add_to_body << content
      end

      def res
        i = @html.index("</body>")
        @html = @html.insert(i, @to_add_to_body.join("")) if i
        i = @html.index("</head>")
        @html = @html.insert(i, @to_add_to_head.join("")) if i
        @html
      end
    end

    class Util
      # reads the literal contents of the file in assets/#{name}
      # if any vars are supplied, do a simple string substitution of the vars for their values
      def self.read_asset(name, vars = {})
        contents = File.read(File.join(File.dirname(__FILE__), "assets", name))
        if vars.any?
          vars.each_pair{|k,v| contents.gsub!(k.to_s,v.to_s)}
        end
        contents
      end
    end

    # Note that this middleware never even gets inserted unless Rails environment is development (See Railtie)
    class Middleware
      def initialize(app)
        @app = app
      end

      def call(env)
        rack_response = @app.call(env)
        begin
          DevTraceResponseManipulator.new(env, rack_response).call
        rescue Exception => e
          # If anything went wrong at all, just bail out and return the unmodified response.
          ScoutApm::Agent.instance.context.logger.debug("DevTrace: Raised an exception: #{e.message}, #{e.backtrace}")
          rack_response
        end
      end
    end

    class DevTraceResponseManipulator
      attr_reader :rack_response
      attr_reader :rack_status, :rack_headers, :rack_body
      attr_reader :env

      def initialize(env, rack_response)
        @env = env
        @rack_response = rack_response

        @rack_status = rack_response[0]
        @rack_headers = rack_response[1]
        @rack_body = rack_response[2]
      end

      def call
        return rack_response unless preconditions_met?

        if ajax_request?
          ScoutApm::Agent.instance.context.logger.debug("DevTrace: in middleware, dev_trace is active, and response has a body. This is either AJAX or JSON. Path=#{path}; ContentType=#{content_type}")
          adjust_ajax_header
        else
          adjust_html_response
        end

        rebuild_rack_response
      end

      ###########################
      #  Precondition checking  #
      ###########################

      def preconditions_met?
        if dev_trace_disabled?
          # The line below is very noise as it is called on every request.
          # logger.debug("DevTrace: isn't activated via config. Try: SCOUT_DEV_TRACE=true rails server")
          return false
        end

        # Don't attempt to instrument assets.
        # Don't log this case, since it would be very noisy
        logger.debug("DevTrace: dev asset ignored") and return false if development_asset?

        # If we didn't have a tracked_request object, or we explicitly ignored
        # this request, don't do any work.
        logger.debug("DevTrace: no tracked request") and return false if tracked_request.nil? || tracked_request.ignoring_request?

        # If we didn't get a trace, we can't show a trace...
        if trace.nil?
          logger.debug("DevTrace: in middleware, dev_trace is active, and response has a body, but no trace was found. Path=#{path}; ContentType=#{content_type}")
          return false
        end

        true
      end

      def dev_trace_disabled?
        ! ScoutApm::Agent.instance.context.config.value('dev_trace')
      end

      ########################
      #  Response Injection  #
      ########################

      def rebuild_rack_response
        [rack_status, rack_headers, rack_body]
      end

      def adjust_ajax_header
        rack_headers['X-scoutapminstant'] = payload
      end

      def adjust_html_response
        case true
        when older_rails_response? then adjust_older_rails_response
        when newer_rails_response? then adjust_newer_rails_response
        when rack_proxy_response? then  adjust_rack_proxy_response
        else
          # No action taken, we only adjust if we know exactly what we have.
        end
      end

      def older_rails_response?
        if defined?(ActionDispatch::Response)
          return true if rack_body.is_a?(ActionDispatch::Response)
        end
      end

      def newer_rails_response?
        if defined?(ActionDispatch::Response::RackBody)
          return true if rack_body.is_a?(ActionDispatch::Response::RackBody)
        end
      end

      def rack_proxy_response?
        rack_body.is_a?(::Rack::BodyProxy)
      end

      def adjust_older_rails_response
        logger.debug("DevTrace: in middleware, dev_trace is active, and response has a (older) body. This appears to be an HTML page and an ActionDispatch::Response. Path=#{path}; ContentType=#{content_type}")
        rack_body.body = [ html_manipulator.res ]
      end

      # Preserve the ActionDispatch::Response object we're working with
      def adjust_newer_rails_response
        logger.debug("DevTrace: in middleware, dev_trace is active, and response has a (newer) body. This appears to be an HTML page and an ActionDispatch::Response. Path=#{path}; ContentType=#{content_type}")
        @rack_body = [ html_manipulator.res ]
      end

      def adjust_rack_proxy_response
        logger.debug("DevTrace: in middleware, dev_trace is active, and response has a body. This appears to be an HTML page and an Rack::BodyProxy. Path=#{path}; ContentType=#{content_type}")
        @rack_body = [ html_manipulator.res ]
        @rack_headers.delete("Content-Length")
      end

      def html_manipulator
        @html_manipulator ||=
          begin
            page = ScoutApm::Instant::Page.new(rack_body.body)

            # This monkey-patches XMLHttpRequest. It could possibly be part of the main scout_instant.js too. Putting it here so it runs as soon as possible.
            page.add_to_head(ScoutApm::Instant::Util.read_asset("xmlhttp_instrumentation.html"))

            # Add a link to CSS, then JS
            page.add_to_head("<link href='#{apm_host}/instant/scout_instant.css?cachebust=#{Time.now.to_i}' media='all' rel='stylesheet' />")
            page.add_to_body("<script src='#{apm_host}/instant/scout_instant.js?cachebust=#{Time.now.to_i}'></script>")
            page.add_to_body("<script>var scoutInstantPageTrace=#{payload};window.scoutInstant=window.scoutInstant('#{apm_host}', scoutInstantPageTrace)</script>")

            page
          end
      end

      def ajax_request?
        env['HTTP_X_REQUESTED_WITH'] == 'XMLHttpRequest' || content_type.include?("application/json")
      end

      def development_asset?
        !rack_body.respond_to?(:body)
      end

      def path
        env['PATH_INFO']
      end

      def content_type
        rack_headers['Content-Type']
      end

      ##############################
      #  APM Helpers & Shorthands  #
      ##############################

      def logger
        ScoutApm::Agent.instance.context.logger
      end

      def tracked_request
        @tracked_request ||= ScoutApm::RequestManager.lookup
      end

      def apm_host
        ScoutApm::Agent.instance.context.config.value("direct_host")
      end

      def trace
        @trace ||=
          begin
            layer_finder = LayerConverters::FindLayerByType.new(tracked_request)
            converter = LayerConverters::SlowRequestConverter.new(ScoutApm::Agent.instance.context, tracked_request, layer_finder, ScoutApm::FakeStore.new)
            converter.call
          end
      end

      def payload
        @payload ||=
          begin
            metadata = {
              :app_root      => ScoutApm::Agent.instance.context.environment.root.to_s,
              :unique_id     => env['action_dispatch.request_id'], # note, this is a different unique_id than what "normal" payloads use
              :agent_version => ScoutApm::VERSION,
              :platform      => "ruby",
            }

            hash = ScoutApm::Serializers::PayloadSerializerToJson.
              rearrange_slow_transaction(trace).
              merge!(:metadata => metadata)
            ScoutApm::Serializers::PayloadSerializerToJson.jsonify_hash(hash)
          end
      end

    end
  end
end
