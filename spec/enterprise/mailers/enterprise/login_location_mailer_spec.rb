require 'rails_helper'
require Rails.root.join 'spec/mailers/administrator_notifications/shared/smtp_config_shared.rb'

RSpec.describe Enterprise::LoginLocationMailer do
  include_context 'with smtp config'

  let(:user) { create(:user, email: 'agent@example.com') }
  let(:meta) { { city: 'Mumbai', country: 'India', ip: '203.0.113.7', browser_name: 'Chrome', platform_name: 'macOS' } }
  let(:mail) { described_class.new_location(user, meta).deliver_now }

  it 'sends to the user with the location and device details' do
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
