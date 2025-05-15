require 'rails_helper'

describe MessageTemplates::Template::CsatSurvey do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:service) { described_class.new(conversation: conversation) }

  describe '#perform' do
    context 'when no survey rules are configured' do
      it 'creates a CSAT survey message' do
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
      before do
        allow(conversation).to receive(:cached_label_list).and_return('support, urgent')
      end

      it 'creates a CSAT survey message' do
        service.perform

        expect(conversation.messages.template.count).to eq(1)
        message = conversation.messages.template.first
        expect(message.content_type).to eq('input_csat')
        expect(message.content).to eq('Please rate your experience')
        expect(message.content_attributes['display_type']).to eq('emoji')
      end
    end

    context 'when conversation has no matching labels' do
      before do
        allow(conversation).to receive(:cached_label_list).and_return('billing, payment')
      end

      it 'does not create a CSAT survey message' do
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
      before do
        allow(conversation).to receive(:cached_label_list).and_return('billing, payment')
      end

      it 'creates a CSAT survey message' do
        service.perform

        expect(conversation.messages.template.count).to eq(1)
        expect(conversation.messages.template.first.content_type).to eq('input_csat')
      end
    end

    context 'when conversation has matching labels' do
      before do
        allow(conversation).to receive(:cached_label_list).and_return('support, urgent')
      end

      it 'does not create a CSAT survey message' do
        service.perform

        expect(conversation.messages.template.count).to eq(0)
      end
    end
  end

  describe '#conversation_labels' do
    context 'when cached_label_list is present' do
      before do
        allow(conversation).to receive(:cached_label_list).and_return('support, help, urgent')
      end

      it 'returns the cached label list as an array' do
        expect(service.send(:conversation_labels)).to eq(%w[support help urgent])
      end
    end

    context 'when cached_label_list is not present' do
      before do
        allow(conversation).to receive(:cached_label_list).and_return(nil)
      end

      it 'returns an empty array' do
        expect(service.send(:conversation_labels)).to eq([])
      end
    end

    context 'when cached_label_list is empty' do
      before do
        allow(conversation).to receive(:cached_label_list).and_return('')
      end

      it 'returns an empty array' do
        expect(service.send(:conversation_labels)).to eq([])
      end
    end
  end

  describe '#survey_rules_configured?' do
    context 'when inbox has no csat_config' do
      before do
        allow(inbox).to receive(:csat_config).and_return(nil)
      end

      it 'returns false' do
        expect(service.send(:survey_rules_configured?)).to be_falsey
      end
    end

    context 'when inbox has no survey_rules' do
      before do
        allow(inbox).to receive(:csat_config).and_return({ 'display_type' => 'emoji' })
      end

      it 'returns false' do
        expect(service.send(:survey_rules_configured?)).to be_falsey
      end
    end

    context 'when survey_rules values is not an array' do
      before do
        allow(inbox).to receive(:csat_config).and_return({
                                                           'survey_rules' => { 'operator' => 'contains', 'values' => 'support' }
                                                         })
      end

      it 'returns false' do
        expect(service.send(:survey_rules_configured?)).to be_falsey
      end
    end

    context 'when survey_rules values is an empty array' do
      before do
        allow(inbox).to receive(:csat_config).and_return({
                                                           'survey_rules' => { 'operator' => 'contains', 'values' => [] }
                                                         })
      end

      it 'returns false' do
        expect(service.send(:survey_rules_configured?)).to be_falsey
      end
    end

    context 'when survey_rules are properly configured' do
      before do
        allow(inbox).to receive(:csat_config).and_return({
                                                           'survey_rules' => { 'operator' => 'contains', 'values' => %w[support help] }
                                                         })
      end

      it 'returns true' do
        expect(service.send(:survey_rules_configured?)).to be_truthy
      end
    end
  end

  describe '#build_content_attributes' do
    context 'when display_type is configured' do
      before do
        allow(inbox).to receive(:csat_config).and_return({
                                                           'display_type' => 'star'
                                                         })
      end

      it 'includes display_type in content attributes' do
        attributes = service.send(:build_content_attributes)
        expect(attributes[:display_type]).to eq('star')
      end
    end

    context 'when display_type is not configured' do
      before do
        allow(inbox).to receive(:csat_config).and_return({})
      end

      it 'returns an empty hash' do
        attributes = service.send(:build_content_attributes)
        expect(attributes).to eq({})
      end
    end
  end

  describe '#custom_message' do
    context 'when inbox has a custom message configured' do
      before do
        allow(inbox).to receive(:csat_config).and_return({
                                                           'message' => 'How would you rate your support experience?'
                                                         })
      end

      it 'returns the custom message' do
        expect(service.send(:custom_message)).to eq('How would you rate your support experience?')
      end
    end

    context 'when inbox has no custom message' do
      before do
        allow(inbox).to receive(:csat_config).and_return({})
        allow(I18n).to receive(:t).with('conversations.templates.csat_input_message_body').and_return('Default message')
      end

      it 'returns the default message from I18n' do
        expect(service.send(:custom_message)).to eq('Default message')
      end
    end
  end
end
