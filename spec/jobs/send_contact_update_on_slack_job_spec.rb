require 'rails_helper'

RSpec.describe SendContactUpdateOnSlackJob do
  let(:account) { create(:account) }
  let(:contact) { create(:contact, account: account) }
  let(:hook) { create(:integrations_hook, app_id: 'slack', account: account) }
  let(:service) { instance_double(Integrations::Slack::SendContactUpdateService, perform: nil) }

  it 'invokes SendContactUpdateService with the contact, hook, and changed_attributes' do
    changed_attributes = { 'email' => [nil, 'new@example.com'] }

    expect(Integrations::Slack::SendContactUpdateService)
      .to receive(:new).with(contact: contact, hook: hook, changed_attributes: changed_attributes).and_return(service)
    expect(service).to receive(:perform)

    described_class.perform_now(contact, hook, changed_attributes)
  end
end
