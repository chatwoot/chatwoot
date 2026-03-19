require 'rails_helper'

RSpec.describe ContactMergeAction do
  describe 'enterprise company association on merge' do
    let(:account) { create(:account) }
    let(:base_contact) { create(:contact, account: account, email: nil, company: nil) }
    let(:mergee_contact) { create(:contact, account: account, email: nil, company: nil) }

    before do
      create(:contact_email, contact: mergee_contact, account: account, email: 'owner@acme.com', primary: true)
    end

    it 'associates a company when the merged contact gains its first business email' do
      expect do
        described_class.new(account: account, base_contact: base_contact, mergee_contact: mergee_contact).perform
      end.to change(Company, :count).by(1)

      expect(base_contact.reload.company).to be_present
      expect(base_contact.company.domain).to eq('acme.com')
    end
  end
end
