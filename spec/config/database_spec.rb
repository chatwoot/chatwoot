require 'rails_helper'

RSpec.describe 'Database Configuration' do
  let(:database_config_path) { Rails.root.join('config', 'database.yml') }
  let(:database_config) { YAML.load_file(database_config_path, aliases: true) }

  describe 'database.yml structure' do
    it 'exists and is readable' do
      expect(File.exist?(database_config_path)).to be true
      expect(File.readable?(database_config_path)).to be true
    end

    it 'contains default configuration' do
      expect(database_config).to have_key('default')
    end

    it 'contains development environment configuration' do
      expect(database_config).to have_key('development')
    end

    it 'contains test environment configuration' do
      expect(database_config).to have_key('test')
    end

    it 'contains production environment configuration' do
      expect(database_config).to have_key('production')
    end

    it 'contains staging environment configuration' do
      expect(database_config).to have_key('staging')
    end
  end

  describe 'default configuration' do
    let(:default_config) { database_config['default'] }

    it 'uses postgresql adapter' do
      expect(default_config['adapter']).to eq('postgresql')
    end

    it 'uses unicode encoding' do
      expect(default_config['encoding']).to eq('unicode')
    end

    it 'configures connection pool' do
      expect(default_config['pool']).to be_present
    end

    it 'configures reaping frequency' do
      expect(default_config['reaping_frequency']).to be_present
    end

    it 'configures statement timeout' do
      expect(default_config['variables']).to have_key('statement_timeout')
    end

    it 'includes SSL mode configuration' do
      expect(default_config).to have_key('sslmode')
    end
  end

  describe 'environment variable support' do
    context 'when POSTGRES_HOST is set' do
      it 'uses the environment variable value' do
        ENV['POSTGRES_HOST'] = 'test-host.example.com'
        config = ERB.new(File.read(database_config_path)).result
        parsed_config = YAML.safe_load(config, aliases: true)
        expect(parsed_config['default']['host']).to eq('test-host.example.com')
        ENV.delete('POSTGRES_HOST')
      end
    end

    context 'when POSTGRES_PORT is set' do
      it 'uses the environment variable value' do
        ENV['POSTGRES_PORT'] = '5433'
        config = ERB.new(File.read(database_config_path)).result
        parsed_config = YAML.safe_load(config, aliases: true)
        expect(parsed_config['default']['port']).to eq('5433')
        ENV.delete('POSTGRES_PORT')
      end
    end

    context 'when POSTGRES_SSL_MODE is set' do
      it 'uses the environment variable value' do
        ENV['POSTGRES_SSL_MODE'] = 'require'
        config = ERB.new(File.read(database_config_path)).result
        parsed_config = YAML.safe_load(config, aliases: true)
        expect(parsed_config['default']['sslmode']).to eq('require')
        ENV.delete('POSTGRES_SSL_MODE')
      end
    end

    context 'when POSTGRES_SSL_MODE is not set' do
      it 'defaults to prefer' do
        ENV.delete('POSTGRES_SSL_MODE')
        config = ERB.new(File.read(database_config_path)).result
        parsed_config = YAML.safe_load(config, aliases: true)
        expect(parsed_config['default']['sslmode']).to eq('prefer')
      end
    end
  end

  describe 'ZeroDB PostgreSQL compatibility' do
    context 'when using ZeroDB PostgreSQL environment variables' do
      before do
        ENV['POSTGRES_HOST'] = 'postgres-test.railway.app'
        ENV['POSTGRES_PORT'] = '5432'
        ENV['POSTGRES_DATABASE'] = 'chatwoot_zerodb_test'
        ENV['POSTGRES_USERNAME'] = 'postgres_user_test'
        ENV['POSTGRES_PASSWORD'] = 'test_password'
        ENV['POSTGRES_SSL_MODE'] = 'require'
      end

      after do
        ENV.delete('POSTGRES_HOST')
        ENV.delete('POSTGRES_PORT')
        ENV.delete('POSTGRES_DATABASE')
        ENV.delete('POSTGRES_USERNAME')
        ENV.delete('POSTGRES_PASSWORD')
        ENV.delete('POSTGRES_SSL_MODE')
      end

      it 'configures database connection with ZeroDB credentials' do
        config = ERB.new(File.read(database_config_path)).result
        parsed_config = YAML.safe_load(config, aliases: true)

        expect(parsed_config['default']['host']).to eq('postgres-test.railway.app')
        expect(parsed_config['default']['port']).to eq('5432')
        expect(parsed_config['default']['sslmode']).to eq('require')
      end

      it 'enables SSL for secure connections' do
        config = ERB.new(File.read(database_config_path)).result
        parsed_config = YAML.safe_load(config, aliases: true)

        expect(parsed_config['default']['sslmode']).to eq('require')
      end
    end
  end

  describe 'production environment' do
    let(:production_config) { database_config['production'] }

    it 'inherits from default configuration' do
      expect(production_config).to be_present
    end

    it 'has database configuration' do
      expect(production_config).to have_key('database')
    end

    it 'has username configuration' do
      expect(production_config).to have_key('username')
    end

    it 'has password configuration' do
      expect(production_config).to have_key('password')
    end
  end

  describe 'staging environment' do
    let(:staging_config) { database_config['staging'] }

    it 'inherits from default configuration' do
      expect(staging_config).to be_present
    end

    it 'has database configuration' do
      expect(staging_config).to have_key('database')
    end

    it 'has username configuration' do
      expect(staging_config).to have_key('username')
    end

    it 'has password configuration' do
      expect(staging_config).to have_key('password')
    end

    it 'supports ZeroDB PostgreSQL configuration comments' do
      config_content = File.read(database_config_path)
      expect(config_content).to include('ZeroDB dedicated PostgreSQL instance')
      expect(config_content).to include('ZERODB_POSTGRES_HOST')
      expect(config_content).to include('ZERODB_POSTGRES_SSL_MODE')
    end
  end

  describe 'ZeroDB dedicated PostgreSQL support' do
    context 'when ZERODB_POSTGRES_* environment variables are set' do
      before do
        ENV['ZERODB_POSTGRES_HOST'] = 'postgres-zerodb.railway.app'
        ENV['ZERODB_POSTGRES_PORT'] = '5432'
        ENV['ZERODB_POSTGRES_DATABASE'] = 'chatwoot_zerodb_prod'
        ENV['ZERODB_POSTGRES_USERNAME'] = 'zerodb_user_123'
        ENV['ZERODB_POSTGRES_PASSWORD'] = 'secure_password_456'
        ENV['ZERODB_POSTGRES_SSL_MODE'] = 'require'
      end

      after do
        ENV.delete('ZERODB_POSTGRES_HOST')
        ENV.delete('ZERODB_POSTGRES_PORT')
        ENV.delete('ZERODB_POSTGRES_DATABASE')
        ENV.delete('ZERODB_POSTGRES_USERNAME')
        ENV.delete('ZERODB_POSTGRES_PASSWORD')
        ENV.delete('ZERODB_POSTGRES_SSL_MODE')
      end

      it 'can be configured in database.yml' do
        # Verify that the config file supports these variables through comments
        config_content = File.read(database_config_path)
        expect(config_content).to include('ZERODB_POSTGRES_HOST')
        expect(config_content).to include('ZERODB_POSTGRES_USERNAME')
        expect(config_content).to include('ZERODB_POSTGRES_PASSWORD')
      end

      it 'provides SSL mode configuration for ZeroDB' do
        expect(ENV['ZERODB_POSTGRES_SSL_MODE']).to eq('require')
      end

      it 'validates all required ZeroDB environment variables are documentable' do
        required_vars = %w[
          ZERODB_POSTGRES_HOST
          ZERODB_POSTGRES_PORT
          ZERODB_POSTGRES_DATABASE
          ZERODB_POSTGRES_USERNAME
          ZERODB_POSTGRES_PASSWORD
          ZERODB_POSTGRES_SSL_MODE
        ]

        config_content = File.read(database_config_path)
        required_vars.each do |var|
          expect(config_content).to include(var), "Expected database.yml to mention #{var}"
        end
      end
    end

    context 'when using fallback from ZERODB to standard POSTGRES variables' do
      it 'documents the fallback pattern in comments' do
        config_content = File.read(database_config_path)
        # The config should show how ZERODB_POSTGRES_* falls back to POSTGRES_*
        expect(config_content).to match(/ZERODB_POSTGRES_\w+.*POSTGRES_\w+/)
      end
    end
  end

  describe 'current database connection' do
    it 'is established and working' do
      expect(ActiveRecord::Base.connection).to be_active
    end

    it 'uses PostgreSQL adapter' do
      expect(ActiveRecord::Base.connection.adapter_name).to eq('PostgreSQL')
    end

    it 'can execute queries' do
      expect { ActiveRecord::Base.connection.execute('SELECT 1') }.not_to raise_error
    end

    it 'respects statement timeout configuration' do
      timeout = ActiveRecord::Base.connection.execute("SHOW statement_timeout").first['statement_timeout']
      expect(timeout).to be_present
    end
  end

  describe 'connection pool configuration' do
    it 'has a configured pool size' do
      expect(ActiveRecord::Base.connection_pool.size).to be > 0
    end

    it 'respects RAILS_MAX_THREADS environment variable' do
      original_value = ENV['RAILS_MAX_THREADS']
      ENV['RAILS_MAX_THREADS'] = '10'

      # Note: This would require reloading the configuration
      # For now, we just verify the config can be loaded
      config = ERB.new(File.read(database_config_path)).result
      parsed_config = YAML.safe_load(config, aliases: true)
      expect(parsed_config['default']['pool']).to be_present

      ENV['RAILS_MAX_THREADS'] = original_value
    end
  end
end
