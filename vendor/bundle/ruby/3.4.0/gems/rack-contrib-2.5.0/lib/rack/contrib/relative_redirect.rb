# frozen_string_literal: true

require 'rack'

# Rack::RelativeRedirect is a simple middleware that converts relative paths in
# redirects in absolute urls, so they conform to RFC2616. It allows the user to
# specify the absolute path to use (with a sensible default), and handles
# relative paths (those that don't start with a slash) as well.
class Rack::RelativeRedirect
  SCHEME_MAP = {'http'=>'80', 'https'=>'443'}
  # The default proc used if a block is not provided to .new
  # Just uses the url scheme of the request and the server name.
  DEFAULT_ABSOLUTE_PROC = proc do |env, res|
    port = env['SERVER_PORT']
    scheme = env['rack.url_scheme']
    "#{scheme}://#{env['SERVER_NAME']}#{":#{port}" unless SCHEME_MAP[scheme] == port}"
  end

  # Initialize a new RelativeRedirect object with the given arguments.  Arguments:
  # * app : The next middleware in the chain.  This is always called.
  # * &block : If provided, it is called with the environment and the response
  #   from the next middleware. It should return a string representing the scheme
  #   and server name (such as 'http://example.org').
  def initialize(app, &block)
    @app = app
    @absolute_proc = block || DEFAULT_ABSOLUTE_PROC
  end

  # Call the next middleware with the environment.  If the request was a
  # redirect (response status 301, 302, or 303), and the location header does
  # not start with an http or https url scheme, call the block provided by new
  # and use that to make the Location header an absolute url.  If the Location
  # does not start with a slash, make location relative to the path requested.
  def call(env)
    status, headers, body = @app.call(env)
    headers_klass = Rack.release < "3" ? Rack::Utils::HeaderHash : Rack::Headers
    headers = headers_klass.new.merge(headers)

    if [301,302,303, 307,308].include?(status) and loc = headers['Location'] and !%r{\Ahttps?://}o.match(loc)
      absolute = @absolute_proc.call(env, [status, headers, body])
      headers['Location'] = if %r{\A/}.match(loc)
        "#{absolute}#{loc}"
      else
        "#{absolute}#{File.dirname(Rack::Utils.unescape(env['PATH_INFO']))}/#{loc}"
      end
    end

    [status, headers, body]
  end
end
