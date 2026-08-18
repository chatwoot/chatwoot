# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PortalTicketAccessMailer do
  describe 'access_link' do
    let!(:account) { create(:account) }
    let!(:portal) { create(:portal, account: account, name: 'Acme Help') }
    let(:contact) { create(:contact, account: account, email: 'customer@example.com') }
    let(:verify_url) { 'https://help.example.com/hc/acme/tickets/verify?token=abc' }
    let(:class_instance) { described_class.new }

    before do
      allow(described_class).to receive(:new).and_return(class_instance)
      allow(class_instance).to receive(:smtp_config_set_or_development?).and_return(true)
    end

    it 'sends the magic link to the contact' do
      mail = described_class.access_link(portal: portal, contact: contact, verify_url: verify_url).deliver_now

      expect(mail.to).to eq([contact.email])
      expect(mail.subject).to eq('Your ticket access link for Acme Help')
      expect(mail.body.encoded).to include(verify_url)
      expect(mail.body.encoded).to include('Acme Help')
    end

    it 'does not send when smtp is not configured' do
      allow(class_instance).to receive(:smtp_config_set_or_development?).and_return(false)

      mail = described_class.access_link(portal: portal, contact: contact, verify_url: verify_url).deliver_now

      expect(mail).to be_nil
    end
  end
end
