require 'rails_helper'
require Rails.root.join('lib/cloudwatch_reporter_config')

describe CloudwatchReporterConfig do
  subject(:config) { described_class.new('WEB_CLOUDWATCH_') }

  describe '#interval' do
    it 'defaults to 60 seconds' do
      with_modified_env WEB_CLOUDWATCH_INTERVAL: nil do
        expect(config.interval).to eq(60)
      end
    end

    it 'uses a configured positive value, including below the standard resolution' do
      with_modified_env WEB_CLOUDWATCH_INTERVAL: '15' do
        expect(config.interval).to eq(15)
      end
    end

    # A zero or negative interval would make the reporter thread busy-loop.
    ['', '0', '-5', 'not-a-number'].each do |value|
      it "falls back to 60 seconds for #{value.inspect}" do
        with_modified_env WEB_CLOUDWATCH_INTERVAL: value do
          expect(config.interval).to eq(60)
        end
      end
    end
  end

  describe '#client' do
    before do
      allow(Aws::InstanceProfileCredentials).to receive(:new).and_return(instance_double(Aws::InstanceProfileCredentials))
    end

    it 'prefers the dedicated region over the shared storage region' do
      with_modified_env WEB_CLOUDWATCH_AWS_REGION: 'eu-west-1', AWS_REGION: 'ap-south-1' do
        expect(config.client.config.region).to eq('eu-west-1')
      end
    end

    it 'falls back to the shared storage region' do
      with_modified_env WEB_CLOUDWATCH_AWS_REGION: nil, AWS_REGION: 'ap-south-1' do
        expect(config.client.config.region).to eq('ap-south-1')
      end
    end

    it 'falls back to a default when the shared region is present but blank' do
      with_modified_env WEB_CLOUDWATCH_AWS_REGION: nil, AWS_REGION: '' do
        expect(config.client.config.region).to eq('us-east-1')
      end
    end

    it 'uses dedicated credentials when they are set' do
      with_modified_env WEB_CLOUDWATCH_AWS_ACCESS_KEY_ID: 'dedicated-key', WEB_CLOUDWATCH_AWS_SECRET_ACCESS_KEY: 'dedicated-secret' do
        expect(config.client.config.credentials.credentials.access_key_id).to eq('dedicated-key')
      end
    end

    it 'raises when a dedicated key is set without its secret' do
      with_modified_env WEB_CLOUDWATCH_AWS_ACCESS_KEY_ID: 'dedicated-key', WEB_CLOUDWATCH_AWS_SECRET_ACCESS_KEY: nil do
        expect { config.client }.to raise_error(KeyError)
      end
    end

    # The shared AWS_ACCESS_KEY_ID is scoped to storage and cannot publish metrics, so an
    # unconfigured reporter must reach for the instance role rather than the default chain.
    it 'uses the instance role when no dedicated credentials are set' do
      with_modified_env WEB_CLOUDWATCH_AWS_ACCESS_KEY_ID: nil, AWS_ACCESS_KEY_ID: 'storage-key' do
        config.client
      end

      expect(Aws::InstanceProfileCredentials).to have_received(:new)
    end
  end

  it 'reads only its own prefix' do
    with_modified_env SIDEKIQ_CLOUDWATCH_INTERVAL: '30', WEB_CLOUDWATCH_INTERVAL: nil do
      expect(config.interval).to eq(60)
    end
  end
end
