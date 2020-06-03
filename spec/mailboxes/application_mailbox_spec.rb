require 'rails_helper'

RSpec.describe ApplicationMailbox, type: :mailbox do
  include ActionMailbox::TestHelper

  describe 'route the inbound mail to appropriate mailbox' do
    let(:welcome_mail) { create_inbound_email_from_fixture('welcome.eml') }
    let(:reply_mail) { create_inbound_email_from_fixture('reply.eml') }

    it 'catchall mails route to default inbox' do
      dbl = double
      expect(DefaultMailbox).to receive(:new).and_return(dbl)
      expect(dbl).to receive(:perform_processing).and_return(true)
      described_class.route welcome_mail
    end

    it 'routes reply emails to Conversation Mailbox' do
      dbl = double
      expect(ConversationMailbox).to receive(:new).and_return(dbl)
      expect(dbl).to receive(:perform_processing).and_return(true)
      described_class.route reply_mail
    end
  end
end
