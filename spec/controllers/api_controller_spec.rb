require 'rails_helper'

RSpec.describe 'API Base', type: :request do
  describe 'request to api base url' do
    it 'returns api version' do
      get '/api/'
      expect(response).to have_http_status(:success)
      expect(response.body).to include(Chatwoot.config[:version])
      expect(response.body).to include('queue_services')
      expect(response.body).to include('data_services')
    end

    it 'returns null mobile app minimum versions when not configured' do
      get '/api/'
      expect(response.parsed_body['mobile_app']).to eq('min_version' => { 'ios' => nil, 'android' => nil })
    end

    it 'returns the configured mobile app minimum versions' do
      create(:installation_config, name: 'MOBILE_APP_MIN_IOS_VERSION', value: '4.10.0')
      create(:installation_config, name: 'MOBILE_APP_MIN_ANDROID_VERSION', value: '4.9.8')
      GlobalConfig.clear_cache

      get '/api/'
      expect(response.parsed_body['mobile_app']).to eq('min_version' => { 'ios' => '4.10.0', 'android' => '4.9.8' })
    end

    context 'when the database connection has not been opened yet' do
      # Rails opens pooled connections lazily, on their first query.
      let(:unopened_connection) do
        ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.new(ActiveRecord::Base.connection_db_config.configuration_hash)
      end

      before { allow(ActiveRecord::Base).to receive(:connection).and_return(unopened_connection) }
      after { unopened_connection.disconnect! }

      it 'reports data services as ok' do
        get '/api/'
        expect(response.parsed_body['data_services']).to eq('ok')
      end
    end

    context 'when the database is unreachable' do
      let(:unreachable_connection) do
        ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.new(
          ActiveRecord::Base.connection_db_config.configuration_hash.merge(host: '127.0.0.1', port: 1)
        )
      end

      before { allow(ActiveRecord::Base).to receive(:connection).and_return(unreachable_connection) }

      it 'reports data services as failing' do
        get '/api/'
        expect(response.parsed_body['data_services']).to eq('failing')
      end
    end
  end
end
