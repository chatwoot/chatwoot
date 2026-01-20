# frozen_string_literal: true

RSpec.shared_examples 'encrypted external credential' do |factory:, attribute:, value: 'secret-token'|
  before do
    skip('encryption keys missing; see run_mfa_spec workflow') unless Chatwoot.encryption_configured?
    if defined?(Facebook::Messenger::Subscriptions)
      allow(Facebook::Messenger::Subscriptions).to receive(:subscribe).and_return(true)
      allow(Facebook::Messenger::Subscriptions).to receive(:unsubscribe).and_return(true)
    end
  end

  it "encrypts #{attribute} at rest" do
    record = create(factory, attribute => value)

    raw_stored_value = record.reload.read_attribute_before_type_cast(attribute).to_s
    expect(raw_stored_value).to be_present
    expect(raw_stored_value).not_to include(value)
    expect(record.public_send(attribute)).to eq(value)
    expect(record.encrypted_attribute?(attribute)).to be(true)
  end
end
