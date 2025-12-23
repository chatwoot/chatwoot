# frozen_string_literal: true

module Rack
  # Lighttpd sets the wrong SCRIPT_NAME and PATH_INFO if you mount your
  # FastCGI app at "/". This middleware fixes this issue.

  class LighttpdScriptNameFix
    def initialize(app)
      @app = app
    end

    def call(env)
      env["PATH_INFO"] = env["SCRIPT_NAME"].to_s + env["PATH_INFO"].to_s
      env["SCRIPT_NAME"] = ""
      @app.call(env)
    end
  end
end
