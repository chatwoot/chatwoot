module SearchIndexing::Store
  PREFIX = 'search_indexing:v1'.freeze
  REGISTRY_KEY = "#{PREFIX}:streams".freeze
  EPOCH_KEY = "#{PREFIX}:epoch".freeze
  SEQUENCE_KEY = "#{PREFIX}:sequence".freeze

  def self.epoch
    run('epoch', [EPOCH_KEY, SEQUENCE_KEY, REGISTRY_KEY], [SecureRandom.hex(12)])
  end

  def self.run(script, keys, arguments)
    source = Rails.root.join('enterprise/lib/search_indexing', "#{script}.lua").read
    Redis::Alfred.with { |redis| redis.eval(source, keys: keys, argv: arguments) }
  end

  def self.due_streams
    Redis::Alfred.with do |redis|
      redis.zrangebyscore(REGISTRY_KEY, '-inf', Time.current.to_f, limit: [0, 100])
    end
  end
end
