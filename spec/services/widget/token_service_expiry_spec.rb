require 'rails_helper'

RSpec.describe Widget::TokenService, type: :service do
  describe 'token expiry configuration' do
    let(:service) { described_class.new(payload: {}) }

    before do
      # Clear any existing configs to ensure test isolation
      InstallationConfig.where(name: 'WIDGET_TOKEN_EXPIRY').destroy_all
    end

    context 'with valid configuration' do
      before do
        create(:installation_config, name: 'WIDGET_TOKEN_EXPIRY', value: '30')
      end

      it 'uses the configured value for token expiry' do
        travel_to '2025-01-01' do
          token = service.generate_token
          decoded = JWT.decode(token, Rails.application.secret_key_base, true, algorithm: 'HS256').first
          expect(decoded['iat']).to eq(Time.zone.now.to_i)
          expect(decoded['exp']).to eq(Time.zone.now.to_i + 30.days.to_i)
        end
      end
    end

    context 'with empty configuration' do
      before do
        create(:installation_config, name: 'WIDGET_TOKEN_EXPIRY', value: '')
      end

      it 'uses the default expiry' do
        travel_to '2025-01-01' do
          token = service.generate_token
          decoded = JWT.decode(token, Rails.application.secret_key_base, true, algorithm: 'HS256').first
          expect(decoded['iat']).to eq(Time.zone.now.to_i)
          expect(decoded['exp']).to eq(Time.zone.now.to_i + 180.days.to_i)
        end
      end
    end
  end
end
