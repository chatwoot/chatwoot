require 'rails_helper'
RSpec.describe MailPresenter do
  include ActionMailbox::TestHelper

  describe 'parsed mail decorator' do
    let(:mail) { create_inbound_email_from_fixture('welcome.eml').mail }
    let(:decorated_mail) { described_class.new(mail) }

    let(:mail_with_no_subject) { create_inbound_email_from_fixture('mail_with_no_subject.eml').mail }
    let(:decorated_mail_with_no_subject) { described_class.new(mail_with_no_subject) }

    it 'give default subject line if mail subject is empty' do
      expect(decorated_mail_with_no_subject.subject).to eq('')
    end

    it 'give utf8 encoded content' do
      expect(decorated_mail.subject).to eq("Discussion: Let's debate these attachments")
      expect(decorated_mail.text_content[:full]).to eq("Let's talk about these images:\r\n\r\n")
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
      expect(data[:multipart]).to eq(true)
      expect(data[:subject]).to eq(decorated_mail.subject)
    end

    it 'give email from in downcased format' do
      expect(decorated_mail.from.first.eql?(mail.from.first.downcase)).to eq true
    end
  end
end
