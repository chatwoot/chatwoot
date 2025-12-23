# frozen_string_literal: true

require_relative 'body_proxy'

module Rack
  # Rack::Lock locks every request inside a mutex, so that every request
  # will effectively be executed synchronously.
  class Lock
    def initialize(app, mutex = Mutex.new)
      @app, @mutex = app, mutex
    end

    def call(env)
      @mutex.lock
      begin
        response = @app.call(env)
        returned = response << BodyProxy.new(response.pop) { unlock }
      ensure
        unlock unless returned
      end
    end

    private

    def unlock
      @mutex.unlock
    end
  end
end
