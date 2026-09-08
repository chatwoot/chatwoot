require 'rails_helper'

RSpec.describe Enterprise::AuditLogSessionIpLookupJob do
  let(:account) { create(:account).tap { |record| record.enable_features!(:ip_lookup) } }
  let(:other_account) { create(:account).tap { |record| record.enable_features!(:ip_lookup) } }
  let(:user) { create(:user, account: account) }
  let(:request_uuid) { SecureRandom.uuid }
  let(:geo_result) { OpenStruct.new(city: 'Mountain View', country: 'United States', country_code: 'US') }
  let(:ip_lookup) { instance_double(IpLookupService) }

  before { allow(IpLookupService).to receive(:new).and_return(ip_lookup) }

  def create_session_audit(associated:, remote_address: '8.8.8.8', uuid: request_uuid)
    Enterprise::AuditLog.create!(auditable: user, action: 'sign_in', associated: associated,
                                 remote_address: remote_address, request_uuid: uuid)
  end

  it 'resolves the address once and applies it to every row of the request' do
    audits = [create_session_audit(associated: account), create_session_audit(associated: other_account)]
    allow(ip_lookup).to receive(:perform).with('8.8.8.8').and_return(geo_result)

    described_class.perform_now(request_uuid, '8.8.8.8')

    expect(ip_lookup).to have_received(:perform).once
    audits.each do |audit|
      expect(audit.reload.city).to eq('Mountain View')
      expect(audit.country_code).to eq('US')
    end
  end

  it 'leaves rows belonging to another request alone' do
    create_session_audit(associated: account)
    untouched = create_session_audit(associated: account, uuid: SecureRandom.uuid)
    allow(ip_lookup).to receive(:perform).and_return(geo_result)

    described_class.perform_now(request_uuid, '8.8.8.8')

    expect(untouched.reload.city).to be_nil
  end

  it 'skips accounts that have not enabled ip_lookup' do
    opted_out = create(:account)
    audit = create_session_audit(associated: opted_out)
    allow(ip_lookup).to receive(:perform).and_return(geo_result)

    described_class.perform_now(request_uuid, '8.8.8.8')

    expect(audit.reload.city).to be_nil
    expect(IpLookupService).not_to have_received(:new)
  end

  it 'is a no-op when the request has no eligible rows' do
    described_class.perform_now(request_uuid, '8.8.8.8')

    expect(IpLookupService).not_to have_received(:new)
  end

  it 'swallows lookup errors so a flaky geocoder does not poison the queue' do
    create_session_audit(associated: account)
    allow(ip_lookup).to receive(:perform).and_raise(StandardError.new('boom'))

    expect { described_class.perform_now(request_uuid, '8.8.8.8') }.not_to raise_error
  end
end
