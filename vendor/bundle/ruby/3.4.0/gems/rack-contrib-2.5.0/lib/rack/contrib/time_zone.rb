# frozen_string_literal: true

module Rack
  class TimeZone
    Javascript = <<-EOJ
    function setTimezoneCookie() {
      var offset = (new Date()).getTimezoneOffset()
      var date = new Date();
      date.setTime(date.getTime()+3600000);
      document.cookie = "utc_offset="+offset+"; expires="+date.toGMTString();+"; path=/";
    }
EOJ

    def initialize(app)
      @app = app
    end

    def call(env)
      request = Rack::Request.new(env)
      if utc_offset = request.cookies["utc_offset"]
        env["rack.timezone.utc_offset"] = -(utc_offset.to_i * 60)
      end

      @app.call(env)
    end
  end
end
