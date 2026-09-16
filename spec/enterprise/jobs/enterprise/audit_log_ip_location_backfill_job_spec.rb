require 'rails_helper'

RSpec.describe Enterprise::AuditLogIpLocationBackfillJob do
  include ActiveJob::TestHelper

  let(:account) { create(:account).tap { |record| record.enable_features!(:ip_lookup) } }
  let(:inbox) { create(:inbox, account: account) }
  let(:lookup) { instance_double(IpLookupService, perform: nil) }

  # Keep resolution a cheap no-op so rows stay selectable and the cursor advances by id.
  before { allow(IpLookupService).to receive(:new).and_return(lookup) }

  def create_audit(**attrs)
    Enterprise::AuditLog.create!(auditable: inbox, action: 'update', associated: account, **attrs)
  end

  it 'resolves the batch and reschedules itself from the last processed id' do
    create_audit(remote_address: '1.1.1.1')
    last = create_audit(remote_address: '2.2.2.2')
    clear_enqueued_jobs

    described_class.perform_now(0)

    expect(described_class).to have_been_enqueued.with(last.id)
  end

  it 'keeps the chain going when a row cannot be resolved' do
    create_audit(remote_address: '1.1.1.1')
    last = create_audit(remote_address: '2.2.2.2')
    allow(lookup).to receive(:perform).with('1.1.1.1').and_raise(StandardError.new('boom'))
    clear_enqueued_jobs

    described_class.perform_now(0)

    expect(described_class).to have_been_enqueued.with(last.id)
  end

  it 'skips audits whose account has not enabled ip_lookup' do
    opted_out = create(:account)
    Enterprise::AuditLog.create!(auditable: create(:inbox, account: opted_out), action: 'update',
                                 associated: opted_out, remote_address: '3.3.3.3')
    clear_enqueued_jobs

    described_class.perform_now(0)

    expect(described_class).not_to have_been_enqueued
  end

  it 'stops rescheduling when no rows remain' do
    create_audit(remote_address: '1.1.1.1')
    clear_enqueued_jobs

    described_class.perform_now(Enterprise::AuditLog.maximum(:id))

    expect(described_class).not_to have_been_enqueued
  end
end
