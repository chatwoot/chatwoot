require 'rails_helper'
require Rails.root.join 'spec/mailers/administrator_notifications/shared/smtp_config_shared.rb'

RSpec.describe EmailDeliveryTestMailer do
  include_context 'with smtp config'

  let(:user) { create(:user, email: 'agent@example.com') }
  let(:mail) { described_class.delivery_test(user).message }

  it 'sends a plain-text test email with no links' do
    expect(mail.to).to eq(['agent@example.com'])
    expect(mail.from).to eq([Mail::Address.new(ApplicationMailer.default[:from]).address])
    expect(mail.mime_type).to eq('text/plain')
    expect(mail.body.encoded).to include('confirm we can reach your inbox')
    expect(mail.body.encoded).not_to include('http')
  end

  it 'does not send when SMTP is not configured' do
    with_modified_env('SMTP_ADDRESS' => nil) do
      expect(mail).to be_a(ActionMailer::Base::NullMail)
    end
  end
end
