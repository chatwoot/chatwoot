require 'rails_helper'

describe MessageTemplates::Template::CsatSurvey do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:service) { described_class.new(conversation: conversation) }

  describe '#perform' do
    context 'when no survey rules are configured' do
      it 'creates a CSAT survey message' do
        inbox.update!(csat_config: {})

        service.perform

        expect(conversation.messages.template.count).to eq(1)
        expect(conversation.messages.template.first.content_type).to eq('input_csat')
      end
    end

    context 'when the inbox has no configured message' do
      before { inbox.update!(csat_config: {}) }

      # The job that resolves a conversation runs with the process default locale, not the
      # account's, so this reproduces the Sidekiq condition rather than the request one.
      it 'translates the fallback into the locale of the account' do
        account.update!(locale: 'pt_BR')

        I18n.with_locale(:en) { service.perform }

        expect(conversation.messages.template.last.content)
          .to eq(I18n.t('conversations.templates.csat_input_message_body', locale: :pt_BR))
      end

      # Account#locale is an enum over LANGUAGES_CONFIG, which is a wider list than the
      # locale files the installation actually loads. I18n.with_locale raises on the gap.
      it 'falls back to the default locale when the installation did not load the account language' do
        account.update!(locale: 'pt_BR')
        allow(I18n).to receive(:available_locales).and_return([:en])

        expect { service.perform }.not_to raise_error
        expect(conversation.messages.template.last.content)
          .to eq(I18n.t('conversations.templates.csat_input_message_body', locale: :en))
      end
    end

    context 'when csat config is provided' do
      let(:csat_config) do
        {
          'display_type' => 'star',
          'message' => 'Please rate your experience'
        }
      end

      before { inbox.update(csat_config: csat_config) }

      it 'creates a CSAT message with configured attributes' do
        service.perform

        message = conversation.messages.template.last
        expect(message.content_type).to eq('input_csat')
        expect(message.content).to eq('Please rate your experience')
        expect(message.content_attributes['display_type']).to eq('star')
      end
    end
  end
end
