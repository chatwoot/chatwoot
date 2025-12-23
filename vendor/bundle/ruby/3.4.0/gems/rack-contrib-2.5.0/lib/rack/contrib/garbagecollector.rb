# frozen_string_literal: true

module Rack
  # Forces garbage collection after each request.
  class GarbageCollector
    def initialize(app)
      @app = app
    end

    def call(env)
      @app.call(env)
    ensure
      GC.start
    end
  end
end
