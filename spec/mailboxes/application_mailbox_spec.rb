require 'rails_helper'

RSpec.describe ApplicationMailbox, type: :mailbox do
  include ActionMailbox::TestHelper

  describe 'route the inbound mail to appropriate mailbox' do
    let(:welcome_mail) { create_inbound_email_from_fixture('welcome.eml') }
    let(:reply_mail) { create_inbound_email_from_fixture('reply.eml') }
    let(:support_mail) { create_inbound_email_from_fixture('support.eml') }

    describe 'Default' do
      it 'catchall mails route to Default Mailbox' do
        dbl = double
        expect(DefaultMailbox).to receive(:new).and_return(dbl)
        expect(dbl).to receive(:perform_processing).and_return(true)
        described_class.route welcome_mail
      end
    end

    describe 'Reply' do
      it 'routes reply emails to Reply Mailbox' do
        dbl = double
        expect(ReplyMailbox).to receive(:new).and_return(dbl)
        expect(dbl).to receive(:perform_processing).and_return(true)
        described_class.route reply_mail
      end
    end

    describe 'Support' do
      let!(:channel_email) { create(:channel_email) }

      before do
        # this email is hardcoded in the support.eml, that's why we are updating this
        channel_email.email = 'care@example.com'
        channel_email.save
      end

      it 'routes support emails to Support Mailbox' do
        dbl = double
        expect(SupportMailbox).to receive(:new).and_return(dbl)
        expect(dbl).to receive(:perform_processing).and_return(true)
        described_class.route support_mail
      end
    end
  end
end
