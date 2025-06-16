require 'rails_helper'

describe Digitaltolk::Openai::Translation::SetDetectedLocale do
  subject { described_class.new(message, target_language_locale, same_language, force: force) }

  let(:force) { false }
  let(:message) { create(:message) }
  let(:target_language_locale) { 'en' }
  let(:same_language) { true }

  before do
    subject.perform
    message.reload
  end

  describe '#perform' do
    it 'updates the detected locale' do
      expect(message.translations['detected_locale']).to eq({ target_language_locale => same_language })
    end

    context 'when detected_locale is already false' do
      let(:message) { create(:message, translations: { 'detected_locale' => detected_locale }) }
      let(:detected_locale) do
        {
          target_language_locale => false
        }
      end

      it 'does not change the detected locale' do
        expect(message.translations['detected_locale']).to eq({
                                                                target_language_locale => false
                                                              })
      end

      context 'when force is true' do
        let(:force) { true }
        let(:same_language) { true }

        it 'updates the detected locale even if it was previously false' do
          expect(message.translations['detected_locale']).to eq({
                                                                  target_language_locale => true
                                                                })
        end
      end
    end
  end
end
