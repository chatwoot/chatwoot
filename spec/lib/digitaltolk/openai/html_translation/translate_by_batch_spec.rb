require 'rails_helper'

describe Digitaltolk::Openai::HtmlTranslation::TranslateByBatch do
  subject { described_class.new(message, target_language) }

  let(:message) { create(:message, content: 'This is a test message', content_attributes: content_attributes) }
  let(:target_language) { 'en' }

  let(:content_attributes) do
    {
      'email' => {
        'html_content' => {
          'full' => full_html_content
        }
      }
    }
  end

  let(:full_html_content) do
    [
      "<p>#{'a' * 1000}</p>",
      "<p>#{'b' * 1000}</p>",
      "<p>#{'c' * 1000}</p>",
      "<p>#{'d' * 1000}</p>"
    ].join
  end

  describe '#perform' do
    context 'when the HTML content is empty' do
      let(:full_html_content) { '' }

      it 'does not to trigger any TranslationForBatchHtmlJob' do
        subject.perform

        expect(Digitaltolk::TranslationForBatchHtmlJob).not_to have_been_enqueued
      end
    end

    context 'when the HTML content is nil' do
      let(:full_html_content) { nil }

      it 'does not to trigger any TranslationForBatchHtmlJob' do
        subject.perform

        expect(Digitaltolk::TranslationForBatchHtmlJob).not_to have_been_enqueued
      end
    end
  end
end
