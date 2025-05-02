require 'rails_helper'

RSpec.describe AccountDeletionService do
  let(:account) { create(:account) }
  let(:mailer) { double(deliver_later: nil) }

  describe '#perform' do
    before do
      allow(DeleteObjectJob).to receive(:perform_later)
      allow(AdministratorNotifications::AccountComplianceMailer).to receive(:with).and_return(
        double(account_deleted: mailer)
      )
    end

    it 'enqueues DeleteObjectJob with the account' do
      described_class.new(account: account).perform

      expect(DeleteObjectJob).to have_received(:perform_later).with(account)
    end

    it 'sends a compliance notification email' do
      described_class.new(account: account).perform

      expect(AdministratorNotifications::AccountComplianceMailer).to have_received(:with).with(account: account)
      expect(mailer).to have_received(:deliver_later)
    end
  end
end
