class MockRedis
  class IndifferentHash < Hash
    def has_key?(key)
      super(key.to_s)
    end

    def key?(key)
      super(key.to_s)
    end
  end
end
