require 'rails_helper'

RSpec.describe Captain::EmailVerificationMailer do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account, name: 'Acme Support') }
  let(:encrypted_code) { Captain::EmailVerification.encrypt_code('482913') }
  let(:mail) { described_class.with(account: account).verification_code(inbox, 'jane@example.com', encrypted_code).message }

  it 'sends the code to the address, from the inbox name' do
    expect(mail.to).to eq(['jane@example.com'])
    expect(mail[:from].display_names).to eq(['Acme Support'])
    expect(mail.body.encoded).to include('482913').and include('30 minutes')
  end

  it 'keeps the code out of the subject' do
    expect(mail.subject).to eq('Your Acme Support verification code')
  end

  it 'keeps an inbox name with a comma as one sender' do
    inbox.update!(name: 'Acme, Inc')

    expect(mail[:from].addrs.map { |address| [address.display_name, address.address] }).to eq([['Acme, Inc', mail.from.first]])
    expect(mail.from.size).to eq(1)
  end

  it 'takes the subject and the body text from translations' do
    allow(I18n).to receive(:t).and_call_original
    allow(I18n).to receive(:t).with('captain.email_verification.subject', inbox_name: 'Acme Support').and_return('Votre code')
    allow(I18n).to receive(:t).with('captain.email_verification.heading').and_return('Votre code de verification')

    expect(mail.subject).to eq('Votre code')
    expect(mail.body.encoded).to include('Votre code de verification')
  end

  describe '.deliverable?' do
    it 'is false when SMTP is not configured' do
      with_modified_env SMTP_ADDRESS: nil do
        expect(described_class.deliverable?).to be(false)
      end
    end

    it 'is true when SMTP is configured' do
      with_modified_env SMTP_ADDRESS: 'smtp.example.com' do
        expect(described_class.deliverable?).to be(true)
      end
    end
  end
end
