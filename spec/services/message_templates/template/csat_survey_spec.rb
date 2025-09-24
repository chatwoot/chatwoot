require 'rails_helper'

describe MessageTemplates::Template::CsatSurvey do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:service) { described_class.new(conversation: conversation) }

  describe '#perform' do
    context 'when no survey rules are configured' do
      it 'creates a CSAT survey message' do
        inbox.update(csat_config: {})

        service.perform

        expect(conversation.messages.template.count).to eq(1)
        expect(conversation.messages.template.first.content_type).to eq('input_csat')
      end
    end
  end

  describe '#perform with contains operator' do
    let(:csat_config) do
      {
        'display_type' => 'emoji',
        'message' => 'Please rate your experience',
        'survey_rules' => {
          'operator' => 'contains',
          'values' => %w[support help]
        }
      }
    end

    before do
      inbox.update(csat_config: csat_config)
    end

    context 'when conversation has matching labels' do
      it 'creates a CSAT survey message' do
        conversation.update(label_list: %w[support urgent])

        service.perform

        expect(conversation.messages.template.count).to eq(1)
        message = conversation.messages.template.first
        expect(message.content_type).to eq('input_csat')
        expect(message.content).to eq('Please rate your experience')
        expect(message.content_attributes['display_type']).to eq('emoji')
      end
    end

    context 'when conversation has no matching labels' do
      it 'does not create a CSAT survey message' do
        conversation.update(label_list: %w[billing-support payment])

        service.perform

        expect(conversation.messages.template.count).to eq(0)
      end
    end
  end

  describe '#perform with does_not_contain operator' do
    let(:csat_config) do
      {
        'display_type' => 'emoji',
        'message' => 'Please rate your experience',
        'survey_rules' => {
          'operator' => 'does_not_contain',
          'values' => %w[support help]
        }
      }
    end

    before do
      inbox.update(csat_config: csat_config)
    end

    context 'when conversation does not have matching labels' do
      it 'creates a CSAT survey message' do
        conversation.update(label_list: %w[billing payment])

        service.perform

        expect(conversation.messages.template.count).to eq(1)
        expect(conversation.messages.template.first.content_type).to eq('input_csat')
      end
    end

    context 'when conversation has matching labels' do
      it 'does not create a CSAT survey message' do
        conversation.update(label_list: %w[support urgent])

        service.perform

        expect(conversation.messages.template.count).to eq(0)
      end
    end
  end
end
