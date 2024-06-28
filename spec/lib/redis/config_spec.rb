require 'rails_helper'

describe Redis::Config do
  context 'when single redis instance is used' do
    let(:redis_url) { 'redis://my-redis-instance:6379' }
    let(:redis_pasword) { 'some-strong-password' }

    before do
      described_class.instance_variable_set(:@config, nil)
      with_modified_env REDIS_URL: redis_url, REDIS_PASSWORD: redis_pasword, REDIS_SENTINELS: '', REDIS_SENTINEL_MASTER_NAME: '' do
        described_class.config
      end
    end

    it 'checks for app redis config' do
      app_config = described_class.app
      expect(app_config.keys).to contain_exactly(:url, :password, :timeout, :reconnect_attempts, :ssl_params)
      expect(app_config[:url]).to eq(redis_url)
      expect(app_config[:password]).to eq(redis_pasword)
    end
  end

  context 'when redis sentinel is used' do
    let(:redis_url) { 'redis://my-redis-instance:6379' }
    let(:redis_sentinels) { 'sentinel_1:1234, sentinel_2:4321, sentinel_3' }
    let(:redis_master_name) { 'master-name' }
    let(:redis_pasword) { 'some-strong-password' }

    let(:expected_sentinels) do
      [
        { host: 'sentinel_1', port: '1234', password: 'some-strong-password' },
        { host: 'sentinel_2', port: '4321', password: 'some-strong-password' },
        { host: 'sentinel_3', port: '26379', password: 'some-strong-password' }
      ]
    end

    before do
      described_class.instance_variable_set(:@config, nil)
      with_modified_env REDIS_URL: redis_url, REDIS_PASSWORD: redis_pasword, REDIS_SENTINELS: redis_sentinels,
                        REDIS_SENTINEL_MASTER_NAME: redis_master_name do
        described_class.config
      end
    end

    after do
      # ensuring the redis config is unset and won't affect other tests
      described_class.instance_variable_set(:@config, nil)
    end

    it 'checks for app redis config' do
      expect(described_class.app.keys).to contain_exactly(:url, :password, :sentinels, :timeout, :reconnect_attempts, :ssl_params)
      expect(described_class.app[:url]).to eq("redis://#{redis_master_name}")
      expect(described_class.app[:sentinels]).to match_array(expected_sentinels)
    end

    context 'when redis sentinel is used with REDIS_SENTINEL_PASSWORD empty string' do
      let(:redis_sentinel_password) { '' }

      before do
        described_class.instance_variable_set(:@config, nil)
        with_modified_env REDIS_URL: redis_url, REDIS_PASSWORD: redis_pasword, REDIS_SENTINELS: redis_sentinels,
                          REDIS_SENTINEL_MASTER_NAME: redis_master_name, REDIS_SENTINEL_PASSWORD: redis_sentinel_password do
          described_class.config
        end
      end

      after do
        # ensuring the redis config is unset and won't affect other tests
        described_class.instance_variable_set(:@config, nil)
      end

      it 'checks for app redis config and sentinel passwords will be empty' do
        expect(described_class.app.keys).to contain_exactly(:url, :password, :sentinels, :timeout, :reconnect_attempts, :ssl_params)
        expect(described_class.app[:url]).to eq("redis://#{redis_master_name}")
        expect(described_class.app[:sentinels]).to match_array(expected_sentinels.map { |s| s.except(:password) })
      end
    end

    context 'when redis sentinel is used with REDIS_SENTINEL_PASSWORD' do
      let(:redis_sentinel_password) { 'sentinel_password' }

      before do
        described_class.instance_variable_set(:@config, nil)
        with_modified_env REDIS_URL: redis_url, REDIS_PASSWORD: redis_pasword, REDIS_SENTINELS: redis_sentinels,
                          REDIS_SENTINEL_MASTER_NAME: redis_master_name, REDIS_SENTINEL_PASSWORD: redis_sentinel_password do
          described_class.config
        end
      end

      after do
        # ensuring the redis config is unset and won't affect other tests
        described_class.instance_variable_set(:@config, nil)
      end

      it 'checks for app redis config and redis password is replaced in sentinel config' do
        expect(described_class.app.keys).to contain_exactly(:url, :password, :sentinels, :timeout, :reconnect_attempts, :ssl_params)
        expect(described_class.app[:url]).to eq("redis://#{redis_master_name}")
        expect(described_class.app[:sentinels]).to match_array(expected_sentinels.map { |s| s.merge(password: redis_sentinel_password) })
      end
    end
  end
end
