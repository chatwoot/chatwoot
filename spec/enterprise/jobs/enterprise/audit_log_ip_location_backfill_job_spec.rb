require 'rails_helper'

RSpec.describe Enterprise::AuditLogIpLocationBackfillJob do
  include ActiveJob::TestHelper

  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }

  # Keep resolution a cheap no-op so rows stay selectable and the cursor advances by id.
  before { allow(IpLookupService).to receive(:new).and_return(instance_double(IpLookupService, perform: nil)) }

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

  it 'stops rescheduling when no rows remain' do
    create_audit(remote_address: '1.1.1.1')
    clear_enqueued_jobs

    described_class.perform_now(Enterprise::AuditLog.maximum(:id))

    expect(described_class).not_to have_been_enqueued
  end
end
