require 'rails_helper'

describe Notification::FcmService do
  let(:project_id) { 'test_project_id' }
  let(:credentials) { '{ "type": "service_account", "project_id": "test_project_id" }' }
  let(:fcm_service) { described_class.new(project_id, credentials) }
  let(:fcm_double) { instance_double(FCM) }

  before do
    allow(FCM).to receive(:new).and_return(fcm_double)
  end

  describe '#fcm_client' do
    it 'returns an FCM client' do
      expect(fcm_service.fcm_client).to eq(fcm_double)
      expect(FCM).to have_received(:new).with(instance_of(StringIO), project_id)
    end
  end

  describe 'private methods' do
    describe '#credentials_path' do
      it 'creates a StringIO with credentials' do
        string_io = fcm_service.send(:credentials_path)
        expect(string_io).to be_a(StringIO)
        expect(string_io.read).to eq(credentials)
      end
    end
  end
end
