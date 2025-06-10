require 'rails_helper'

describe Digitaltolk::FormatOutgoingEmailService do
  let(:message) { create(:message, content: 'test', message_type: 'outgoing') }
  let(:subject) { described_class.new(message) }

  describe '#perform' do
    shared_examples 'not formatting email' do
      it 'does not format the email' do
        expect { subject.perform }.to_not raise_error
        expect(message&.email).to eq(nil)
      end
    end

    context 'when message is nil' do
      let(:message) { nil }
      it_behaves_like 'not formatting email'
    end
    
    context 'when message_type is not outgoing' do
      let(:message) { create(:message, content: 'test', message_type: 'incoming') }
      it_behaves_like 'not formatting email'
    end

    context 'when email format is existing' do
      let(:message) { create(:message, content: 'test', message_type: 'outgoing', content_attributes: email_content) }
      let(:email_content) do
        {
          email: {
            html_content: {
              full: 'sample'
            }
          }
        }
      end

      it 'reformats email' do
        expect { subject.perform }.not_to raise_error
        expect(message.email).not_to be_nil
        expect(message.email[:html_content][:full]).to include('test')
      end
    end

    it 'updates the content_attributes of the message' do
      subject.perform
      expect(message.email).not_to be_nil
    end

    context 'when message content has HTML tags' do
      let(:content) { "<font color=\"#000000\">Test</span></font>" }
      let(:message) { create(:message, content: content, message_type: 'outgoing') }

      it 'retains the HTML content' do
        subject.perform
        expect(message.email[:html_content][:full]).to include(content)
      end
    end

    it 'generates the html_content' do
      subject.perform
      expect(message.email[:html_content][:full]).to include('test')
    end

    it 'converts \n to <br>' do
      message.update(content: "test\n\n")
      subject.perform
      expect(message.email[:html_content][:full]).to include("test<br/><br/>")
    end
  end
end
