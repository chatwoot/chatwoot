require 'rails_helper'

RSpec.describe Enterprise::AuditLogSessionIpLookupJob do
  let(:account) { create(:account).tap { |record| record.enable_features!(:ip_lookup) } }
  let(:other_account) { create(:account).tap { |record| record.enable_features!(:ip_lookup) } }
  let(:user) { create(:user, account: account) }
  let(:geo_result) { OpenStruct.new(city: 'Mountain View', country: 'United States', country_code: 'US') }
  let(:ip_lookup) { instance_double(IpLookupService) }

  before { allow(IpLookupService).to receive(:new).and_return(ip_lookup) }

  def create_session_audit(associated:, remote_address: '8.8.8.8')
    Enterprise::AuditLog.create!(auditable: user, action: 'sign_in', associated: associated,
                                 remote_address: remote_address, request_uuid: SecureRandom.uuid)
  end

  it 'resolves the address once and applies it to every audit in the batch' do
    audits = [create_session_audit(associated: account), create_session_audit(associated: other_account)]
    allow(ip_lookup).to receive(:perform).with('8.8.8.8').and_return(geo_result)

    described_class.perform_now(audits.map(&:id), '8.8.8.8')

    expect(ip_lookup).to have_received(:perform).once
    audits.each do |audit|
      expect(audit.reload.city).to eq('Mountain View')
      expect(audit.country).to eq('United States')
      expect(audit.country_code).to eq('US')
    end
  end

  it 'leaves audits outside the batch alone' do
    audit = create_session_audit(associated: account)
    untouched = create_session_audit(associated: account)
    allow(ip_lookup).to receive(:perform).and_return(geo_result)

    described_class.perform_now([audit.id], '8.8.8.8')

    expect(untouched.reload.city).to be_nil
  end

  it 'updates only the eligible accounts when a batch spans both' do
    eligible = create_session_audit(associated: account)
    ineligible = create_session_audit(associated: create(:account))
    allow(ip_lookup).to receive(:perform).and_return(geo_result)

    described_class.perform_now([eligible.id, ineligible.id], '8.8.8.8')

    expect(eligible.reload.city).to eq('Mountain View')
    expect(ineligible.reload.city).to be_nil
  end

  it 'skips accounts that have not enabled ip_lookup' do
    audit = create_session_audit(associated: create(:account))

    described_class.perform_now([audit.id], '8.8.8.8')

    expect(IpLookupService).not_to have_received(:new)
  end

  it 'is a no-op when the batch is empty' do
    described_class.perform_now([], '8.8.8.8')

    expect(IpLookupService).not_to have_received(:new)
  end

  it 'swallows lookup errors so a flaky geocoder does not poison the queue' do
    audit = create_session_audit(associated: account)
    allow(ip_lookup).to receive(:perform).and_raise(StandardError.new('boom'))

    expect { described_class.perform_now([audit.id], '8.8.8.8') }.not_to raise_error
  end
end
