require 'rails_helper'
require Rails.root.join 'spec/mailers/administrator_notifications/shared/smtp_config_shared.rb'

RSpec.describe EmailDeliveryTestMailer do
  include_context 'with smtp config'

  let(:mail) { described_class.delivery_test('agent@example.com', 'Jane Agent').message }

  it 'sends a branded test email to the user' do
    expect(mail.to).to eq(['agent@example.com'])
    expect(mail.from).to eq([Mail::Address.new(ApplicationMailer.default[:from]).address])
    expect(mail.subject).to eq('Test email from Chatwoot support')
    expect(mail.body.encoded).to include('Hi Jane Agent,')
    expect(mail.body.encoded).to include('check that emails from Chatwoot reach your inbox')
  end

  it 'uses the installation brand name' do
    allow(GlobalConfig).to receive(:get_value).and_call_original
    allow(GlobalConfig).to receive(:get_value).with('BRAND_NAME').and_return('Acme')

    expect(mail.subject).to eq('Test email from Acme support')
    expect(mail.body.encoded).to include('Test email from Acme')
  end

  it 'greets by address when the name is blank' do
    expect(described_class.delivery_test('agent@example.com', '').message.body.encoded).to include('Hi agent@example.com,')
  end

  it 'does not send when SMTP is not configured' do
    with_modified_env('SMTP_ADDRESS' => nil) do
      expect(mail).to be_a(ActionMailer::Base::NullMail)
    end
  end
end
