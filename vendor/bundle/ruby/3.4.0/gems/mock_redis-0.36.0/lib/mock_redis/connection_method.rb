class MockRedis
  module ConnectionMethod
    def connection
      {
        :host => @base.host,
        :port => @base.port,
        :db => @base.db,
        :id => @base.id,
        :location => "#{@base.host}:#{@base.port}"
      }
    end
  end
end
