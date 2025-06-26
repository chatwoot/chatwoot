require 'rails_helper'

RSpec.describe HealthController, type: :controller do
  describe 'GET #check' do
    before do
      # Stub các health checks để không gọi thực tế
      allow(HealthController).to receive(:db_healthy?).and_return(true)
      allow(HealthController).to receive(:redis_healthy?).and_return(true)
      allow(HealthController).to receive(:sidekiq_healthy?).and_return(true)
    end

    context 'in development environment' do
      before do
        stub_const('Rails', Class.new) unless defined?(Rails)
        allow(Rails).to receive_message_chain(:env, :development?).and_return(true)

        allow(HealthController).to receive(:vite_healthy!).and_return(true)
        allow(HealthController).to receive(:mailhog_healthy!).and_return(true)
      end

      it 'returns HTTP 200 and includes vite and mailhog' do
        get :check
        json = JSON.parse(response.body, symbolize_names: true)

        expect(response).to have_http_status(:ok)
        expect(json.keys).to include(:rails, :database, :redis, :sidekiq, :vite, :mailhog)
        json.each_value do |service|
          expect(service[:status]).to eq(true)
          expect(service[:error]).to be_nil
        end
      end
    end

    context 'in production or test environment (non-development)' do
      before do
        allow(Rails).to receive_message_chain(:env, :development?).and_return(false)
      end

      it 'returns HTTP 200 and excludes vite and mailhog' do
        get :check
        json = JSON.parse(response.body, symbolize_names: true)

        expect(response).to have_http_status(:ok)
        expect(json.keys).to match_array(%i[rails database redis sidekiq])
      end
    end

    context 'when a service fails' do
      before do
        allow(Rails).to receive_message_chain(:env, :development?).and_return(false)
        allow(HealthController).to receive(:redis_healthy?).and_raise('Redis error')
      end

      it 'returns 503 and includes error for the failing service' do
        get :check
        json = JSON.parse(response.body, symbolize_names: true)

        expect(response).to have_http_status(:service_unavailable)
        expect(json[:redis][:status]).to eq(false)
        expect(json[:redis][:error]).to eq('Redis error')
      end
    end
  end
end
