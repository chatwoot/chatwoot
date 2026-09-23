require 'rails_helper'
require Rails.root.join 'spec/mailers/administrator_notifications/shared/smtp_config_shared.rb'

# type: :mailer is required: enterprise specs miss rspec type inference, and without it
# deliver_now uses the real sendmail binary (absent on CI).
RSpec.describe Enterprise::LoginLocationMailer, type: :mailer do
  include_context 'with smtp config'

  let(:meta) do
    { email: 'agent@example.com', city: 'Northtown', country: 'Northland', ip: '203.0.113.7',
      browser_name: 'Chrome', platform_name: 'macOS' }
  end
  let(:mail) { described_class.new_location(meta).deliver_now }

  it 'sends to the captured email with the location and device details' do
    expect(mail.to).to eq(['agent@example.com'])
    expect(mail.subject).to include('New sign-in')
    expect(mail.body.encoded).to include('Northtown')
    expect(mail.body.encoded).to include('Northland')
    expect(mail.body.encoded).to include('Chrome')
  end

  it 'links to the forgot-password page, not a tokenized reset link' do
    expect(mail.body.encoded).to include('/app/auth/reset/password')
    expect(mail.body.encoded).not_to match(/reset_password_token=/)
  end

  it 'tells the user what to do if it was not them' do
    expect(mail.body.encoded).to match(/reset your password/i)
  end

  context 'when a client-supplied device label carries markup' do
    let(:meta) do
      { email: 'agent@example.com', city: 'Northtown', country: 'Northland', ip: '203.0.113.7',
        browser_name: '<a href="https://evil.example">Chrome</a>', platform_name: 'macOS' }
    end

    it 'escapes it instead of rendering the markup' do
      expect(mail.body.encoded).not_to include('<a href="https://evil.example">')
      expect(mail.body.encoded).to include('&lt;a href=')
    end
  end

  it 'uses the configured brand name on white-labeled installations' do
    create(:installation_config, name: 'BRAND_NAME', value: 'Acme Support')
    GlobalConfig.clear_cache
    expect(mail.subject).to eq('New sign-in to your Acme Support account')
    expect(mail.body.encoded).to include('Your Acme Support account')
  end
end
