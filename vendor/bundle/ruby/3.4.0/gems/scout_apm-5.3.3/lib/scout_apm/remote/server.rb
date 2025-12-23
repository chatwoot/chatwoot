# Web Server bound to localhost that listens for remote agent reports. Forwards
# onto the router
module ScoutApm
  module Remote
    class Server
      attr_reader :router
      attr_reader :bind
      attr_reader :port
      attr_reader :logger

      def initialize(bind, port, router, logger)
        @router = router
        @logger = logger
        @bind = bind
        @port = port
        @server = nil
      end

      def require_webrick
        require 'webrick'
        true
      rescue LoadError
        @logger.warn(
          %q|Could not require Webrick. Ruby 3.0 stopped bundling it
             automatically, but it is required to instrument Resque. Please add
             Webrick to your Gemfile.|
        )
        false
      end

      def start
        return false unless require_webrick

        @server = WEBrick::HTTPServer.new(
          :BindAddress => bind,
          :Port => port,
          :AccessLog => [],
          :Logger => @logger
        )

        @server.mount_proc '/' do |request, response|
          router.handle(request.body)

          # arbitrary response, client doesn't expect anything in particular
          response.body = 'Ok'
        end

        @thread = Thread.new do
          begin
            logger.debug("Remote: Starting Server on #{bind}:#{port}")

            @server.start

            logger.debug("Remote: Server returned after #start call, thread exiting")
          rescue => e
            logger.debug("Remote: Server Exception, #{e},\n#{e.backtrace.join("\n\t")}")
          end
        end
      end

      def running?
        @thread.alive?
        @server && @server.status == :Running
      end

      def stop
        @server.stop
        @thread.kill
      end
    end
  end
end
