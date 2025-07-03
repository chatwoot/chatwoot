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
end
