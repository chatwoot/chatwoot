# Force the Vite dev-server proxy to read upstream responses without streaming.
#
# vite_rails inserts `ViteRuby::DevServerProxy` as middleware. In development
# that proxy inherits rack-proxy's default `streaming: true`, which reads the
# upstream body via net_http_hacked and waits for the socket to close to detect
# end-of-body. Vite's dev server answers CSS/SCSS requests over a keep-alive
# connection and never closes it, so the read hangs until the read_timeout
# (~60s) and every stylesheet proxied through Rails fails with Net::ReadTimeout
# — leaving the dashboard unstyled. Disabling streaming makes rack-proxy read
# the body with a normal Net::HTTP request, which handles Vite's
# Content-Length/chunked responses correctly. Production does not insert this
# middleware (run_proxy? is false outside development/test), so this is inert
# there.
if defined?(ViteRuby::DevServerProxy)
  ViteRuby::DevServerProxy.prepend(Module.new do
    def initialize(app = nil, options = {})
      options[:streaming] = false unless options.key?(:streaming)
      # Give genuinely slow first compiles (cold Tailwind + SCSS) headroom
      # instead of failing fast on a long-but-valid request.
      options[:read_timeout] = 300 unless options.key?(:read_timeout)
      super
    end
  end)
end
