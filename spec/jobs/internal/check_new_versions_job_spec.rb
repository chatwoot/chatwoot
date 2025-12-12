require 'rails_helper'

RSpec.describe Internal::CheckNewVersionsJob do
  subject(:job) { described_class.perform_now }

  let(:installation_id) { 'oss-test-uuid' }
  let(:designated_hour) { Digest::MD5.hexdigest(installation_id).hex % 24 }

  before do
    allow(Rails.env).to receive(:production?).and_return(true)
    allow(ChatwootHub).to receive(:installation_identifier).and_return(installation_id)
    allow(Kernel).to receive(:sleep)
    Redis::Alfred.delete('internal::last_version_check_date')
    travel_to Time.zone.parse("2025-12-12 #{designated_hour}:00:00 UTC")
  end

  it 'updates the latest chatwoot version in redis' do
    data = { 'version' => '1.2.3' }
    allow(ChatwootHub).to receive(:sync_with_hub).and_return(data)
    job
    expect(ChatwootHub).to have_received(:sync_with_hub)
    expect(Redis::Alfred.get(Redis::Alfred::LATEST_CHATWOOT_VERSION)).to eq data['version']
  end
end
