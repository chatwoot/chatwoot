# frozen_string_literal: true

module Rack
  class Backstage
    File = ::File

    def initialize(app, path)
      @app = app
      @file = File.expand_path(path)
    end

    def call(env)
      if File.exist?(@file)
        content = File.read(@file)
        length = content.bytesize.to_s
        [503, {'content-type' => 'text/html', 'content-length' => length}, [content]]
      else
        @app.call(env)
      end
    end
  end
end
