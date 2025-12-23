# frozen_string_literal: true

require_relative 'utils'

module Rack
  # Sets an "x-runtime" response header, indicating the response
  # time of the request, in seconds
  #
  # You can put it right before the application to see the processing
  # time, or before all the other middlewares to include time for them,
  # too.
  class Runtime
    FORMAT_STRING = "%0.6f" # :nodoc:
    HEADER_NAME = "x-runtime" # :nodoc:

    def initialize(app, name = nil)
      @app = app
      @header_name = HEADER_NAME
      @header_name += "-#{name.to_s.downcase}" if name
    end

    def call(env)
      start_time = Utils.clock_time
      _, headers, _ = response = @app.call(env)

      request_time = Utils.clock_time - start_time

      unless headers.key?(@header_name)
        headers[@header_name] = FORMAT_STRING % request_time
      end

      response
    end
  end
end
