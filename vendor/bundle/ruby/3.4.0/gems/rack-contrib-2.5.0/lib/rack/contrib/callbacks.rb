# frozen_string_literal: true

module Rack
  class Callbacks
    def initialize(&block)
      @before = []
      @after  = []
      instance_eval(&block) if block_given?
    end

    def before(middleware, *args, &block)
      if block_given?
        @before << middleware.new(*args, &block)
      else
        @before << middleware.new(*args)
      end
    end

    def after(middleware, *args, &block)
      if block_given?
        @after << middleware.new(*args, &block)
      else
        @after << middleware.new(*args)
      end
    end

    def run(app)
      @app = app
    end

    def call(env)
      @before.each {|c| c.call(env) }

      response = @app.call(env)

      @after.inject(response) {|r, c| c.call(r) }
    end
  end
end
