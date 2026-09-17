# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SecurityMailer do
  describe 'account_locked' do
    let(:user) { create(:user) }
    let(:class_instance) { described_class.new }
    let(:mail) { described_class.account_locked(user).deliver_now }

    before do
      allow(described_class).to receive(:new).and_return(class_instance)
      allow(class_instance).to receive(:smtp_config_set_or_development?).and_return(true)
    end

    it 'renders subject and recipient' do
      expect(mail.to).to eq([user.email])
      expect(mail.subject).to eq('Sign-in to your account is temporarily locked')
    end

    it 'mentions the unlock period and the reset path' do
      expect(mail.body.encoded).to include(Devise.unlock_in.in_minutes.to_i.to_s)
      expect(mail.body.encoded).to include('resetting your password')
    end
  end
end
