require 'rails_helper'

RSpec.describe MailboxHelper do
  include ActionMailbox::TestHelper

  # Setup anonymous class
  let(:mailbox_helper_obj) do
    Class.new do
      include MailboxHelper
      attr_accessor :conversation, :processed_mail

      def initialize(conversation, processed_mail)
        @conversation = conversation
        @processed_mail = processed_mail
      end
    end
  end

  let(:mail) { create_inbound_email_from_fixture('welcome.eml').mail }
  let(:processed_mail) { MailPresenter.new(mail) }
  let(:conversation) { create(:conversation) }
  let(:dummy_message) { create(:message) }

  describe '#create_message' do
    before do
      create_list(:message, 5, conversation: conversation)
    end

    context 'when message already exist' do
      it 'creates a new message' do
        helper_instance = mailbox_helper_obj.new(conversation, processed_mail)

        expect(conversation.messages).to receive(:find_by).with(source_id: processed_mail.message_id).and_return(dummy_message)
        expect(conversation.messages).not_to receive(:create!)

        helper_instance.send(:create_message)
      end
    end

    context 'when message does not exist' do
      it 'creates a new message' do
        helper_instance = mailbox_helper_obj.new(conversation, processed_mail)

        expect(conversation.messages).to receive(:find_by).with(source_id: processed_mail.message_id).and_return(nil)
        expect(conversation.messages).to receive(:create!)

        helper_instance.send(:create_message)
      end
    end
  end

  describe '#embed_plain_text_email_with_inline_image' do
    let(:mail_attachment) do
      {
        original: OpenStruct.new(filename: 'image.png'),
        blob: get_blob_for('spec/assets/avatar.png', 'image/png')
      }
    end

    let(:helper_instance) { mailbox_helper_obj.new(conversation, processed_mail) }

    it 'replaces the image tag in the text content' do
      helper_instance.instance_variable_set(:@text_content, 'Hello [image: image.png] World')
      helper_instance.send(:embed_plain_text_email_with_inline_image, mail_attachment)

      text_content = helper_instance.instance_variable_get(:@text_content)

      expect(text_content).to include(Rails.application.routes.url_helpers.url_for(mail_attachment[:blob]))
      expect(text_content).not_to include('[image: avatar.png]')
    end

    it 'replaces the image tag in the text content even if there is not tag to replace' do
      helper_instance.instance_variable_set(:@text_content, 'Hello World')
      helper_instance.send(:embed_plain_text_email_with_inline_image, mail_attachment)

      text_content = helper_instance.instance_variable_get(:@text_content)
      expect(text_content).to include(Rails.application.routes.url_helpers.url_for(mail_attachment[:blob]))
    end
  end

  describe '#add_attachments_to_message' do
    let(:mail) { create_inbound_email_from_fixture('cid_inline_images_without_disposition.eml').mail }
    let(:processed_mail) { MailPresenter.new(mail) }
    let(:conversation) { create(:conversation) }
    let(:helper_instance) { mailbox_helper_obj.new(conversation, processed_mail) }

    before do
      helper_instance.send(:create_message)
    end

    it 'detects inline image attachment by cid reference when Content-Disposition is missing' do
      allow(Rails.application.routes.url_helpers).to receive(:url_for).and_return('/fake-image-url')
      helper_instance.send(:add_attachments_to_message)

      message = conversation.messages[0]

      expect(message.attachments.count).to eq(0)

      html_content = message.content_attributes[:email][:html_content][:full]

      expect(html_content).to include('/fake-image-url"')
      expect(html_content).not_to include('cid:')
    end
  end
end
