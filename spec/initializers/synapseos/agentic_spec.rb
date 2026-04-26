require 'rails_helper'

RSpec.describe Synapseos::Agentic do
  before { described_class.reset! }
  after { described_class.reset! }

  def install_config(name, value)
    config = InstallationConfig.find_or_initialize_by(name: name)
    config.locked = false
    config.value = value
    config.save!
    config
  end

  describe '.client' do
    it 'raises NotConfiguredError when SYNAPSEOS_AGENTIC_ENABLED is false' do
      install_config('SYNAPSEOS_AGENTIC_URL', 'http://agentic.test')
      install_config('SYNAPSEOS_AGENTIC_USER', 'admin')
      install_config('SYNAPSEOS_AGENTIC_PASSWORD', 'secret')
      install_config('SYNAPSEOS_AGENTIC_ENABLED', 'false')
      GlobalConfig.clear_cache

      with_modified_env SYNAPSEOS_AGENTIC_URL: nil, SYNAPSEOS_AGENTIC_USER: nil,
                        SYNAPSEOS_AGENTIC_PASSWORD: nil, SYNAPSEOS_AGENTIC_ENABLED: nil do
        expect { described_class.client }.to raise_error(Synapseos::Agentic::NotConfiguredError)
      end
    end

    it 'returns a memoized AgenticClient when fully configured' do
      install_config('SYNAPSEOS_AGENTIC_URL', 'http://agentic.test')
      install_config('SYNAPSEOS_AGENTIC_USER', 'admin')
      install_config('SYNAPSEOS_AGENTIC_PASSWORD', 'secret')
      install_config('SYNAPSEOS_AGENTIC_ENABLED', 'true')
      GlobalConfig.clear_cache

      with_modified_env SYNAPSEOS_AGENTIC_URL: nil, SYNAPSEOS_AGENTIC_USER: nil,
                        SYNAPSEOS_AGENTIC_PASSWORD: nil, SYNAPSEOS_AGENTIC_ENABLED: nil do
        first = described_class.client
        second = described_class.client
        expect(first).to be_a(Synapseos::AgenticClient)
        expect(first).to equal(second)
      end
    end

    it 'prefers ENV over InstallationConfig when both set' do
      install_config('SYNAPSEOS_AGENTIC_URL', 'http://from-db.test')
      install_config('SYNAPSEOS_AGENTIC_USER', 'db_user')
      install_config('SYNAPSEOS_AGENTIC_PASSWORD', 'db_pass')
      install_config('SYNAPSEOS_AGENTIC_ENABLED', 'true')
      GlobalConfig.clear_cache

      with_modified_env SYNAPSEOS_AGENTIC_URL: 'http://from-env.test',
                        SYNAPSEOS_AGENTIC_USER: 'env_user',
                        SYNAPSEOS_AGENTIC_PASSWORD: 'env_pass',
                        SYNAPSEOS_AGENTIC_ENABLED: 'true' do
        cfg = described_class.config
        expect(cfg[:url]).to eq('http://from-env.test')
        expect(cfg[:user]).to eq('env_user')
        expect(cfg[:password]).to eq('env_pass')
        expect(cfg[:enabled]).to be true
      end
    end
  end
end
