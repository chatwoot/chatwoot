require 'rails_helper'

RSpec.describe Enterprise::AuditLogIpLookupJob do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:audit) do
    Enterprise::AuditLog.create!(auditable: inbox, action: 'update', associated: account, remote_address: '8.8.8.8')
  end
  let(:geo_result) { OpenStruct.new(city: 'Mountain View', country: 'United States', country_code: 'US') }
  let(:ip_lookup) { instance_double(IpLookupService) }

  before { allow(IpLookupService).to receive(:new).and_return(ip_lookup) }

  it 'backfills geo data on the audit' do
    allow(ip_lookup).to receive(:perform).with('8.8.8.8').and_return(geo_result)

    described_class.perform_now(audit)

    audit.reload
    expect(audit.city).to eq('Mountain View')
    expect(audit.country).to eq('United States')
    expect(audit.country_code).to eq('US')
  end

  it 'is a no-op when remote_address is blank' do
    audit.update_columns(remote_address: nil) # rubocop:disable Rails/SkipsModelValidations

    described_class.perform_now(audit)

    expect(IpLookupService).not_to have_received(:new)
  end

  it 'leaves the audit untouched when lookup returns nil' do
    allow(ip_lookup).to receive(:perform).and_return(nil)

    described_class.perform_now(audit)

    audit.reload
    expect(audit.city).to be_nil
    expect(audit.country).to be_nil
  end

  it 'swallows lookup errors so a flaky geocoder does not poison the queue' do
    allow(ip_lookup).to receive(:perform).and_raise(StandardError.new('boom'))

    expect { described_class.perform_now(audit) }.not_to raise_error
  end
end
