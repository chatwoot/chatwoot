# frozen_string_literal: true

require 'rack/proxy'

# Public: Allows to relay asset requests to the Vite development server.
class ViteRuby::DevServerProxy < Rack::Proxy
  HOST_WITH_PORT_REGEX = %r{^(.+?)(:\d+)/}
  VITE_DEPENDENCY_PREFIX = '/@'

  def initialize(app = nil, options = {})
    @vite_ruby = options.delete(:vite_ruby) || ViteRuby.instance
    options[:streaming] = false if config.mode == 'test' && !options.key?(:streaming)
    super
  end

  # Rack: Intercept asset requests and send them to the Vite server.
  def perform_request(env)
    if vite_should_handle?(env) && dev_server_running?
      forward_to_vite_dev_server(env)
      super(env)
    else
      @app.call(env)
    end
  end

private

  extend Forwardable

  def_delegators :@vite_ruby, :config, :dev_server_running?

  def rewrite_uri_for_vite(env)
    uri = env.fetch('REQUEST_URI') { [env['PATH_INFO'], env['QUERY_STRING']].reject { |str| str.to_s.strip.empty? }.join('?') }
    env['PATH_INFO'], env['QUERY_STRING'] = (env['REQUEST_URI'] = normalize_uri(uri)).split('?')
  end

  def normalize_uri(uri)
    uri
      .sub(HOST_WITH_PORT_REGEX, '/') # Hanami adds the host and port.
      .sub('.ts.js', '.ts') # Hanami's javascript helper always adds the extension.
      .sub(/\.(sass|scss|styl|stylus|less|pcss|postcss)\.css$/, '.\1') # Rails' stylesheet_link_tag always adds the extension.
  end

  def forward_to_vite_dev_server(env)
    rewrite_uri_for_vite(env)
    env['QUERY_STRING'] ||= ''
    env['HTTP_HOST'] = env['HTTP_X_FORWARDED_HOST'] = config.host
    env['HTTP_X_FORWARDED_SERVER'] = config.host_with_port
    env['HTTP_PORT'] = env['HTTP_X_FORWARDED_PORT'] = config.port.to_s
    env['HTTP_X_FORWARDED_PROTO'] = env['HTTP_X_FORWARDED_SCHEME'] = config.protocol
    env['HTTPS'] = env['HTTP_X_FORWARDED_SSL'] = 'off' unless config.https
    env['SCRIPT_NAME'] = ''
  end

  def vite_should_handle?(env)
    path = normalize_uri(env['PATH_INFO'])
    return true if path.start_with?(vite_url_prefix) # Vite asset
    return true if file_in_vite_root?(path) # Fallback if Vite can serve the file
  end

  # NOTE: When using an empty 'public_output_dir', we need to rely on a
  # filesystem check to check whether Vite should serve the request.
  def file_in_vite_root?(path)
    path.include?('.') && # Check for extension, avoid filesystem if possible.
      config.vite_root_dir.join(path.start_with?('/') ? path[1..-1] : path).file?
  end

  # NOTE: Vite is configured to use 'public_output_dir' as the base, which can
  # be customized by the user in development to not match any of the routes.
  #
  # If the path starts with that prefix, it will be redirected to Vite.
  def vite_url_prefix
    @vite_url_prefix ||= config.public_output_dir.empty? ? VITE_DEPENDENCY_PREFIX : "/#{ config.public_output_dir }/"
  end
end
