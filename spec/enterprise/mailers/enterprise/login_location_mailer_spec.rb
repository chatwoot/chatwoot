require 'rails_helper'
require Rails.root.join 'spec/mailers/administrator_notifications/shared/smtp_config_shared.rb'

# Type inference does not cover the enterprise namespace, and without type: :mailer
# rspec-rails never forces the :test delivery method, so deliver_now would hit the
# real sendmail binary (absent on CI).
RSpec.describe Enterprise::LoginLocationMailer, type: :mailer do
  include_context 'with smtp config'

  let(:meta) do
    { email: 'agent@example.com', city: 'Mumbai', country: 'India', ip: '203.0.113.7',
      browser_name: 'Chrome', platform_name: 'macOS' }
  end
  let(:mail) { described_class.new_location(meta).deliver_now }

  it 'sends to the captured email with the location and device details' do
    expect(mail.to).to eq(['agent@example.com'])
    expect(mail.subject).to include('New sign-in')
    expect(mail.body.encoded).to include('Mumbai')
    expect(mail.body.encoded).to include('India')
    expect(mail.body.encoded).to include('Chrome')
  end

  it 'links to the forgot-password page, not a tokenized reset link' do
    expect(mail.body.encoded).to include('/app/auth/reset/password')
    expect(mail.body.encoded).not_to match(/reset_password_token=/)
  end

  it 'tells the user what to do if it was not them' do
    expect(mail.body.encoded).to match(/reset your password/i)
  end

end
