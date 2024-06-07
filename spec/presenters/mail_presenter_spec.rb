require 'rails_helper'
RSpec.describe MailPresenter do
  include ActionMailbox::TestHelper

  describe 'parsed mail decorator' do
    let(:mail) { create_inbound_email_from_fixture('welcome.eml').mail }
    let(:multiple_in_reply_to_mail) { create_inbound_email_from_fixture('multiple_in_reply_to.eml').mail }
    let(:mail_without_in_reply_to) { create_inbound_email_from_fixture('reply_cc.eml').mail }
    let(:html_mail) { create_inbound_email_from_fixture('welcome_html.eml').mail }
    let(:ascii_mail) { create_inbound_email_from_fixture('non_utf_encoded_mail.eml').mail }
    let(:decorated_mail) { described_class.new(mail) }

    let(:mail_with_no_subject) { create_inbound_email_from_fixture('mail_with_no_subject.eml').mail }
    let(:decorated_mail_with_no_subject) { described_class.new(mail_with_no_subject) }

    it 'give default subject line if mail subject is empty' do
      expect(decorated_mail_with_no_subject.subject).to eq('')
    end

    it 'give utf8 encoded content' do
      expect(decorated_mail.subject).to eq("Discussion: Let's debate these attachments")
      expect(decorated_mail.text_content[:full]).to eq("Let's talk about these images:\n\n")
    end

    it 'give decoded blob attachments' do
      decorated_mail.attachments.each do |attachment|
        expect(attachment.keys).to eq([:original, :blob])
        expect(attachment[:blob].class.name).to eq('ActiveStorage::Blob')
      end
    end

    it 'give number of attachments of the mail' do
      expect(decorated_mail.number_of_attachments).to eq(2)
    end

    it 'give the serialized data of the email to be stored in the message' do
      data = decorated_mail.serialized_data
      expect(data.keys).to eq([
                                :bcc,
                                :cc,
                                :content_type,
                                :date,
                                :from,
                                :html_content,
                                :in_reply_to,
                                :message_id,
                                :multipart,
                                :number_of_attachments,
                                :subject,
                                :text_content,
                                :to
                              ])
      expect(data[:content_type]).to include('multipart/alternative')
      expect(data[:date].to_s).to eq('2020-04-20T04:20:20-04:00')
      expect(data[:message_id]).to eq(mail.message_id)
      expect(data[:multipart]).to be(true)
      expect(data[:subject]).to eq(decorated_mail.subject)
    end

    it 'give email from in downcased format' do
      expect(decorated_mail.from.first.eql?(mail.from.first.downcase)).to be true
    end

    it 'parse html content in the mail' do
      decorated_html_mail = described_class.new(html_mail)
      expect(decorated_html_mail.subject).to eq('Fwd: How good are you in English? How did you improve your English?')
      expect(decorated_html_mail.text_content[:reply][0..70]).to eq(
        "I'm learning English as a first language for the past 13 years, but to "
      )
    end

    it 'encodes email to UTF-8' do
      decorated_html_mail = described_class.new(ascii_mail)
      expect(decorated_html_mail.subject).to eq('أهلين عميلنا الكريم ')
      expect(decorated_html_mail.text_content[:reply][0..70]).to eq(
        'أنظروا، أنا أحتاجها فقط لتقوم بالتدقيق في مقالتي الشخصية'
      )
    end

    describe '#in_reply_to' do
      context 'when "in_reply_to" is an array' do
        it 'returns the first value from the array' do
          mail_presenter = described_class.new(multiple_in_reply_to_mail)
          expect(mail_presenter.in_reply_to).to eq('4e6e35f5a38b4_479f13bb90078171@small-app-01.mail')
        end
      end

      context 'when "in_reply_to" is not an array' do
        it 'returns the value as is' do
          mail_presenter = described_class.new(mail)
          expect(mail_presenter.in_reply_to).to eq('4e6e35f5a38b4_479f13bb90078178@small-app-01.mail')
        end
      end

      context 'when "in_reply_to" is blank' do
        it 'returns nil' do
          mail_presenter = described_class.new(mail_without_in_reply_to)
          expect(mail_presenter.in_reply_to).to be_nil
        end
      end
    end

    describe 'auto_reply?' do
      let(:auto_reply_mail) { create_inbound_email_from_fixture('auto_reply.eml').mail }
      let(:auto_reply_with_auto_submitted_mail) { create_inbound_email_from_fixture('auto_reply_with_auto_submitted.eml').mail }
      let(:decorated_auto_reply_mail) { described_class.new(auto_reply_mail) }
      let(:decorated_auto_reply_with_auto_submitted_mail) { described_class.new(auto_reply_with_auto_submitted_mail) }

      it 'returns true for auto-reply emails' do
        expect(decorated_auto_reply_mail.auto_reply?).to be true
        expect(decorated_auto_reply_with_auto_submitted_mail.auto_reply?).to be true
      end
    end
  end
end
