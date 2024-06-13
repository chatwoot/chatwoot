require 'rails_helper'

describe Notification::FcmService do
  let(:project_id) { 'test_project_id' }
  let(:credentials) { '{ "type": "service_account", "project_id": "test_project_id" }' }
  let(:fcm_service) { described_class.new(project_id, credentials) }
  let(:fcm_double) { instance_double(FCM) }
  let(:token_info) { { token: 'test_token', expires_at: 1.hour.from_now } }
  let(:creds_double) do
    instance_double(Google::Auth::ServiceAccountCredentials, fetch_access_token!: { 'access_token' => 'test_token', 'expires_in' => 3600 })
  end

  before do
    allow(FCM).to receive(:new).and_return(fcm_double)
    allow(fcm_service).to receive(:generate_token).and_return(token_info)
    allow(Google::Auth::ServiceAccountCredentials).to receive(:make_creds).and_return(creds_double)
  end

  describe '#fcm_client' do
    it 'returns an FCM client' do
      expect(fcm_service.fcm_client).to eq(fcm_double)
      expect(FCM).to have_received(:new).with('test_token', anything, project_id)
    end

    it 'generates a new token if expired' do
      allow(fcm_service).to receive(:generate_token).and_return(token_info)
      allow(fcm_service).to receive(:token_expired?).and_return(true)

      expect(fcm_service.fcm_client).to eq(fcm_double)
      expect(FCM).to have_received(:new).with('test_token', anything, project_id)
      expect(fcm_service).to have_received(:generate_token)
    end
  end

  describe 'private methods' do
    describe '#current_token' do
      it 'returns the current token if not expired' do
        fcm_service.instance_variable_set(:@token_info, token_info)
        expect(fcm_service.send(:current_token)).to eq('test_token')
      end

      it 'generates a new token if expired' do
        expired_token_info = { token: 'expired_token', expires_at: 1.hour.ago }
        fcm_service.instance_variable_set(:@token_info, expired_token_info)
        allow(fcm_service).to receive(:generate_token).and_return(token_info)

        expect(fcm_service.send(:current_token)).to eq('test_token')
        expect(fcm_service).to have_received(:generate_token)
      end
    end

    describe '#generate_token' do
      it 'generates a new token' do
        allow(Google::Auth::ServiceAccountCredentials).to receive(:make_creds).and_return(creds_double)

        token = fcm_service.send(:generate_token)
        expect(token[:token]).to eq('test_token')
        expect(token[:expires_at]).to be_within(1.second).of(Time.zone.now + 3600)
      end
    end

    describe '#credentials_path' do
      it 'creates a StringIO with credentials' do
        string_io = fcm_service.send(:credentials_path)
        expect(string_io).to be_a(StringIO)
        expect(string_io.read).to eq(credentials)
      end
    end
  end
end
