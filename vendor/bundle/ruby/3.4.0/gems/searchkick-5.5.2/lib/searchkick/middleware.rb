require "faraday"

module Searchkick
  class Middleware < Faraday::Middleware
    def call(env)
      path = env[:url].path.to_s
      if path.end_with?("/_search")
        env[:request][:timeout] = Searchkick.search_timeout
      elsif path.end_with?("/_msearch")
        # assume no concurrent searches for timeout for now
        searches = env[:request_body].count("\n") / 2
        # do not allow timeout to exceed Searchkick.timeout
        timeout = [Searchkick.search_timeout * searches, Searchkick.timeout].min
        env[:request][:timeout] = timeout
      end
      @app.call(env)
    end
  end
end
