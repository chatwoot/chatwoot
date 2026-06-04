# frozen_string_literal: true

module Middleware # rubocop:disable Style/ClassAndModuleChildren
  class FazerAiPlatformHeader
    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, response = @app.call(env)
      headers['X-Platform'] = 'fazer.ai'
      [status, headers, response]
    end
  end
end
