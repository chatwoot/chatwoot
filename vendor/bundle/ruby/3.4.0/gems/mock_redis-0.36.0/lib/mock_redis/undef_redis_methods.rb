class MockRedis
  module UndefRedisMethods
    def self.included(klass)
      if klass.instance_methods.map(&:to_s).include?('type')
        klass.send(:undef_method, 'type')
      end
      klass.send(:undef_method, 'exec')
      klass.send(:undef_method, 'select')
    end
  end
end
