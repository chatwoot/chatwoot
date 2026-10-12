require 'rails_helper'

RSpec.describe Captain::EmailVerificationMailer do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account, name: 'Acme Support') }
  let(:encrypted_code) { Captain::EmailVerification.encrypt_code('482913') }
  let(:mail) { described_class.with(account: account).verification_code(inbox, 'jane@example.com', encrypted_code).deliver_now }

  before do
    allow(described_class).to receive(:new).and_wrap_original do |original, *args|
      original.call(*args).tap { |mailer| allow(mailer).to receive(:smtp_config_set_or_development?).and_return(true) }
    end
  end

  it 'sends the code to the address, from the inbox name' do
    expect(mail.to).to eq(['jane@example.com'])
    expect(mail[:from].display_names).to eq(['Acme Support'])
    expect(mail.body.encoded).to include('482913').and include('30 minutes')
  end

  it 'keeps the code out of the subject' do
    expect(mail.subject).to eq('Your Acme Support verification code')
  end
end
