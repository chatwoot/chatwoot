# frozen_string_literal: true

module Rack
  # Middleware to update the process title ($0) with information about the
  # current request. Based loosely on:
  # - http://purefiction.net/mongrel_proctitle/
  # - http://github.com/grempe/thin-proctitle/tree/master
  #
  # NOTE: This will not work properly in a multi-threaded environment.
  class ProcTitle
    F = ::File
    PROGNAME = F.basename($0)

    def initialize(app)
      @app = app
      @appname = Dir.pwd.split('/').reverse.
        find { |name| name !~ /^(\d+|current|releases)$/ } || PROGNAME
      @requests = 0
      $0 = "#{PROGNAME} [#{@appname}] init ..."
    end

    def call(env)
      host, port = env['SERVER_NAME'], env['SERVER_PORT']
      meth, path = env['REQUEST_METHOD'], env['PATH_INFO']
      @requests += 1
      $0 = "#{PROGNAME} [#{@appname}/#{port}] (#{@requests}) " \
           "#{meth} #{path}"

      @app.call(env)
    end
  end
end
