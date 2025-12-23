# frozen_string_literal: true

module Rack
  class RouteExceptions
    ROUTES = [
      [Exception, '/error/internal']
    ]

    PATH_INFO = 'rack.route_exceptions.path_info'.freeze
    EXCEPTION = 'rack.route_exceptions.exception'.freeze
    RETURNED  = 'rack.route_exceptions.returned'.freeze

    class << self
      def route(exception, to)
        ROUTES.delete_if{|k,v| k == exception }
        ROUTES << [exception, to]
      end

      alias []= route
    end

    def initialize(app)
      @app = app
    end

    def call(env, try_again = true)
      returned = @app.call(env)
    rescue Exception => exception
      raise(exception) unless try_again

      ROUTES.each do |klass, to|
        next unless klass === exception
        return route(to, env, returned, exception)
      end

      raise(exception)
    end

    def route(to, env, returned, exception)
      env.merge!(
        PATH_INFO => env['PATH_INFO'],
        EXCEPTION => exception,
        RETURNED => returned
      )

      env['PATH_INFO'] = to

      call(env, try_again = false)
    end
  end
end
