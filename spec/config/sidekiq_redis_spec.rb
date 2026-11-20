require 'rails_helper'

# rubocop:disable RSpec/DescribeClass
describe 'Sidekiq Redis Configuration' do
  # rubocop:enable RSpec/DescribeClass
  let(:client_config) { Sidekiq::Config.new }
  let(:server_config) { Sidekiq::Config.new }
  let(:app_config) { Redis::Config.app.dup }

  before do
    allow(Redis::Config).to receive(:app).and_return(app_config)
    allow(Sidekiq).to receive(:configure_client).and_yield(client_config)
    allow(Sidekiq).to receive(:configure_server).and_yield(server_config)
    allow(Sidekiq).to receive(:server?).and_return(false)

    load Rails.root.join('config/initializers/sidekiq.rb')
  end

  after do
    client_config.redis_pool.shutdown(&:close)
    server_config.redis_pool.shutdown(&:close)
  end

  # Sidekiq raised its default network timeout to 3 s in 7.3 because its BRPOP fetch blocks for 2 s
  # before the read deadline starts; passing the app's 1 s timeout through overrides that default.
  it 'lets Sidekiq apply its own network timeout for the client and server pools' do
    default_pool = Sidekiq::RedisConnection.create(url: app_config[:url])
    sidekiq_default_timeout = default_pool.with { |redis| redis.config.read_timeout }

    [client_config, server_config].each do |config|
      expect(config.redis_pool.with { |redis| redis.config.read_timeout }).to eq(sidekiq_default_timeout)
    end
  ensure
    default_pool&.shutdown(&:close)
  end

  it 'does not change the Redis options used by the rest of the app' do
    expect(app_config).to eq(Redis::Config.config)
  end
end
