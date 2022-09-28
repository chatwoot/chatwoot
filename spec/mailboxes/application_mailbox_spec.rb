require 'rails_helper'

RSpec.describe ApplicationMailbox, type: :mailbox do
  include ActionMailbox::TestHelper

  describe 'route the inbound mail to appropriate mailbox' do
    let(:welcome_mail) { create_inbound_email_from_fixture('welcome.eml') }
    let(:reply_mail) { create_inbound_email_from_fixture('reply.eml') }
    let(:reply_cc_mail) { create_inbound_email_from_fixture('reply_cc.eml') }
    let(:reply_mail_without_uuid) { create_inbound_email_from_fixture('reply.eml') }
    let(:reply_mail_with_in_reply_to) { create_inbound_email_from_fixture('in_reply_to.eml') }
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

      it 'routes reply emails to Reply Mailbox without uuid' do
        dbl = double
        expect(ReplyMailbox).to receive(:new).and_return(dbl)
        expect(dbl).to receive(:perform_processing).and_return(true)
        described_class.route reply_mail_without_uuid
      end
    end

    describe 'Support' do
      let!(:channel_email) { create(:channel_email) }

      it 'routes support emails to Support Mailbox when mail is to channel email' do
        # this email is hardcoded in the support.eml, that's why we are updating this
        channel_email.update(email: 'care@example.com')
        dbl = double
        expect(SupportMailbox).to receive(:new).and_return(dbl)
        expect(dbl).to receive(:perform_processing).and_return(true)
        described_class.route support_mail
      end

      it 'routes support emails to Support Mailbox when mail is to channel forward to email' do
        # this email is hardcoded in the support.eml, that's why we are updating this
        channel_email.update(forward_to_email: 'care@example.com')
        dbl = double
        expect(SupportMailbox).to receive(:new).and_return(dbl)
        expect(dbl).to receive(:perform_processing).and_return(true)
        described_class.route support_mail
      end

      it 'routes support emails to Support Mailbox with cc email' do
        channel_email.update(email: 'test@example.com')
        dbl = double
        expect(SupportMailbox).to receive(:new).and_return(dbl)
        expect(dbl).to receive(:perform_processing).and_return(true)
        described_class.route reply_cc_mail
      end
    end
  end
end
