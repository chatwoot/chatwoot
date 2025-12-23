# frozen_string_literal: true

require_relative 'constants'
require_relative 'body_proxy'

module Rack

  # Middleware tracks and cleans Tempfiles created throughout a request (i.e. Rack::Multipart)
  # Ideas/strategy based on posts by Eric Wong and Charles Oliver Nutter
  # https://groups.google.com/forum/#!searchin/rack-devel/temp/rack-devel/brK8eh-MByw/sw61oJJCGRMJ
  class TempfileReaper
    def initialize(app)
      @app = app
    end

    def call(env)
      env[RACK_TEMPFILES] ||= []

      begin
        _, _, body = response = @app.call(env)
      rescue Exception
        env[RACK_TEMPFILES]&.each(&:close!)
        raise
      end

      response[2] = BodyProxy.new(body) do
        env[RACK_TEMPFILES]&.each(&:close!)
      end

      response
    end
  end
end
