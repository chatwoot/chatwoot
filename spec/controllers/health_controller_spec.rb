require 'rails_helper'

RSpec.describe HealthController, type: :controller do
  describe 'GET #check' do
    let(:expected_keys) { %i[rails database redis sidekiq vite mailhog] }

    before do
      # Stub all health check methods to avoid real connections
      allow(HealthController).to receive(:db_healthy?).and_return(true)
      allow(HealthController).to receive(:redis_healthy?).and_return(true)
      allow(HealthController).to receive(:sidekiq_healthy?).and_return(true)
      allow(HealthController).to receive(:vite_healthy!).and_return(true)
      allow(HealthController).to receive(:mailhog_healthy!).and_return(true)
    end

    context 'when all services are healthy' do
      it 'returns HTTP 200 and all statuses are true' do
        get :check
        json = JSON.parse(response.body, symbolize_names: true)

        expect(response).to have_http_status(:ok)
        expect(json.keys).to match_array(expected_keys)

        json.each_value do |service|
          expect(service[:status]).to eq(true)
          expect(service[:error]).to be_nil
        end
      end
    end

    context 'when one service fails' do
      before do
        allow(HealthController).to receive(:redis_healthy?).and_raise('Redis error')
      end

      it 'returns HTTP 503 and the failing service has status false' do
        get :check
        json = JSON.parse(response.body, symbolize_names: true)

        expect(response).to have_http_status(:service_unavailable)
        expect(json[:redis][:status]).to eq(false)
        expect(json[:redis][:error]).to eq('Redis error')
      end
    end

    context 'when multiple services fail' do
      before do
        allow(HealthController).to receive(:vite_healthy!).and_raise('Vite error')
        allow(HealthController).to receive(:mailhog_healthy!).and_raise('Mailhog error')
      end

      it 'returns HTTP 503 and marks failing services' do
        get :check
        json = JSON.parse(response.body, symbolize_names: true)

        expect(response).to have_http_status(:service_unavailable)
        expect(json[:vite][:status]).to eq(false)
        expect(json[:vite][:error]).to eq('Vite error')

        expect(json[:mailhog][:status]).to eq(false)
        expect(json[:mailhog][:error]).to eq('Mailhog error')
      end
    end
  end
end
