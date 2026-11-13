require 'rails_helper'

RSpec.describe Captain::EmailVerification do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact_inbox) { create(:contact_inbox, inbox: inbox, contact: create(:contact, account: account)) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact_inbox: contact_inbox, contact: contact_inbox.contact) }
  let(:verification) { described_class.new(conversation) }
  let(:email) { "customer-#{SecureRandom.hex(4)}@example.com" }
  let(:emailed_codes) { [] }
  let(:mailer) { class_double(Captain::EmailVerificationMailer) }

  before do
    allow(Captain::EmailVerificationMailer).to receive(:deliverable?).and_return(true)
    allow(Captain::EmailVerificationMailer).to receive(:with).with(account: account).and_return(mailer)
    allow(mailer).to receive(:verification_code) do |_inbox, _email, encrypted_code|
      emailed_codes << described_class.decrypt_code(encrypted_code)
      instance_double(ActionMailer::MessageDelivery, deliver_later: true)
    end
  end

  def conversation_for(conversation_contact_inbox)
    create(:conversation, account: account, inbox: inbox, contact_inbox: conversation_contact_inbox, contact: conversation_contact_inbox.contact)
  end

  def wrong_code
    emailed_codes.last == '000000' ? '111111' : '000000'
  end

  describe '#send_code' do
    it 'emails a 6-digit code to the normalised address' do
      expect(verification.send_code(" #{email.upcase} ")).to eq(:sent)

      expect(emailed_codes.last).to match(/\A\d{6}\z/)
      expect(mailer).to have_received(:verification_code).with(inbox, email, anything)
    end

    it 'never passes the plain code to the mail job' do
      verification.send_code(email)

      expect(mailer).to have_received(:verification_code) do |_inbox, _email, encrypted_code|
        expect(encrypted_code).not_to include(emailed_codes.last)
      end
    end

    it 'rejects an invalid email address' do
      expect(verification.send_code('not-an-email')).to eq(:invalid_email)
      expect(emailed_codes).to be_empty
    end

    it 'rejects an address with characters that can change a URL or a JSON body' do
      ['a@.', 'a@-example.com', 'a@example..com', '.jane@example.com', 'jane..doe@example.com',
       'jane%40example.com#@evil.test', 'jane/invoices@evil.test', 'jane&id=1@evil.test', 'jane","id":"1@evil.test'].each do |address|
        expect(verification.send_code(address)).to eq(:invalid_email)
      end
      expect(emailed_codes).to be_empty
    end

    it 'accepts an address with dots, plus signs, hyphens and underscores' do
      expect(verification.send_code('jane.doe+billing_1@mail-server.example.com')).to eq(:sent)
    end

    it 'sends nothing and stores no code when email cannot be delivered' do
      allow(Captain::EmailVerificationMailer).to receive(:deliverable?).and_return(false)

      expect(verification.send_code(email)).to eq(:unavailable)
      expect(emailed_codes).to be_empty
      expect(verification.verify('000000')).to eq(:expired)
    end

    it 'does not use the send budget when email cannot be delivered' do
      allow(Captain::EmailVerificationMailer).to receive(:deliverable?).and_return(false)
      6.times { verification.send_code(email) }
      allow(Captain::EmailVerificationMailer).to receive(:deliverable?).and_return(true)

      expect(verification.send_code(email)).to eq(:sent)
    end

    it 'allows 5 codes per hour from one contact inbox, across its conversations' do
      results = Array.new(6) { described_class.new(conversation_for(contact_inbox)).send_code("customer-#{SecureRandom.hex(4)}@example.com") }

      expect(results).to eq(([:sent] * 5) + [:rate_limited])
    end

    it 'allows 5 codes per hour from one conversation' do
      results = Array.new(6) { verification.send_code("customer-#{SecureRandom.hex(4)}@example.com") }

      expect(results).to eq(([:sent] * 5) + [:rate_limited])
    end

    it 'does not use the address budget for a contact inbox that is over its own budget' do
      5.times { verification.send_code("customer-#{SecureRandom.hex(4)}@example.com") }
      5.times { verification.send_code(email) }
      other_contact_inbox = create(:contact_inbox, inbox: inbox, contact: create(:contact, account: account))

      expect(described_class.new(conversation_for(other_contact_inbox)).send_code(email)).to eq(:sent)
    end

    it 'allows 5 codes per hour to one email address across contact inboxes' do
      results = Array.new(6) do
        described_class.new(conversation_for(create(:contact_inbox, inbox: inbox, contact: create(:contact, account: account)))).send_code(email)
      end

      expect(results).to eq(([:sent] * 5) + [:rate_limited])
    end

    it 'does not send another code to an address that is already verified' do
      verification.send_code(email)
      verification.verify(emailed_codes.last)

      expect(verification.send_code(email)).to eq(:already_verified)
      expect(emailed_codes.size).to eq(1)
    end

    it 'sends a code to a different address after one is verified' do
      verification.send_code(email)
      verification.verify(emailed_codes.last)

      expect(verification.send_code("other-#{SecureRandom.hex(4)}@example.com")).to eq(:sent)
      expect(verification.verified_email).to eq(email)
    end
  end

  describe '#verify' do
    it 'verifies the address that received the code' do
      verification.send_code(email)

      expect(verification.verify(" #{emailed_codes.last} ")).to eq(:verified)
      expect(verification.verified_email).to eq(email)
      expect(verification.verify(emailed_codes.last)).to eq(:expired)
    end

    it 'rejects a wrong code and counts the attempt' do
      verification.send_code(email)

      expect(verification.verify(wrong_code)).to eq(:invalid_code)
      expect(verification.attempts_left).to eq(4)
      expect(verification.verified_email).to be_nil
    end

    it 'locks the code after 5 wrong attempts' do
      verification.send_code(email)
      5.times { verification.verify(wrong_code) }

      expect(verification.verify(emailed_codes.last)).to eq(:locked)
      expect(verification.verified_email).to be_nil
    end

    it 'gives a new code a full set of attempts' do
      verification.send_code(email)
      5.times { verification.verify(wrong_code) }
      verification.send_code(email)

      expect(verification.verify(emailed_codes.last)).to eq(:verified)
    end

    it 'reports an expired code when none is pending' do
      expect(verification.verify('123456')).to eq(:expired)
    end

    it 'does not accept a code twice' do
      verification.send_code(email)
      verification.verify(emailed_codes.last)

      expect(verification.verify(emailed_codes.last)).to eq(:expired)
    end

    it 'does not accept a code sent in another conversation' do
      other = described_class.new(conversation_for(contact_inbox))
      other.send_code(email)
      other_code = emailed_codes.last
      verification.send_code(email)
      skip 'both codes are the same by chance' if other_code == emailed_codes.last

      expect(verification.verify(other_code)).to eq(:invalid_code)
    end

    it 'keeps the verification to the conversation that entered the code' do
      verification.send_code(email)
      verification.verify(emailed_codes.last)

      expect(described_class.new(conversation_for(contact_inbox)).verified_email).to be_nil
    end

    it 'keeps the verification for 1 hour' do
      verification.send_code(email)
      verification.verify(emailed_codes.last)

      expect(Redis::Alfred.ttl(format(Redis::RedisKeys::CAPTAIN_EMAIL_VERIFICATION_VERIFIED, conversation_id: conversation.id))).to eq(1.hour.to_i)
    end
  end

  describe '#verified_ttl' do
    it 'keeps an email conversation verified for 3 hours' do
      conversation.inbox.update!(channel: create(:channel_email, account: account))

      expect(verification.verified_ttl).to eq(3.hours)
    end
  end
end
