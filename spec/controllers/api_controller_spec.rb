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

    it 'reports the data services as ok against a reachable database' do
      get '/api/'
      expect(response.parsed_body['data_services']).to eq('ok')
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
  end

  describe 'data services probe' do
    let(:controller) { ApiController.new }

    it 'answers ok from a real query, not from connection.active?' do
      expect(controller.send(:postgres_status)).to eq('ok')
    end

    it 'answers ok on a pooled connection that has never been used' do
      # Rails 7.1+ connects lazily: a fresh pool object reports active? == false without touching the database.
      connection = ActiveRecord::Base.connection_pool.checkout
      begin
        allow(connection).to receive(:active?).and_return(false)
        allow(ActiveRecord::Base.connection_pool).to receive(:with_connection).and_yield(connection)
        expect(controller.send(:postgres_status)).to eq('ok')
      ensure
        ActiveRecord::Base.connection_pool.checkin(connection)
      end
    end

    it 'answers failing when no connection can be established' do
      allow(ActiveRecord::Base.connection_pool).to receive(:with_connection).and_raise(ActiveRecord::ConnectionNotEstablished)
      expect(controller.send(:postgres_status)).to eq('failing')
    end

    it 'answers failing when the probe query times out' do
      connection = instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
      allow(ActiveRecord::Base.connection_pool).to receive(:with_connection).and_yield(connection)
      allow(connection).to receive(:transaction).and_yield
      allow(connection).to receive(:execute)
      allow(connection).to receive(:select_value).and_raise(ActiveRecord::QueryCanceled)
      expect(controller.send(:postgres_status)).to eq('failing')
    end
  end
end