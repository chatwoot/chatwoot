require 'rails_helper'

describe CsatSurveyService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account, csat_survey_enabled: true) }
  let(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox, source_id: '+1234567890') }
  let(:conversation) { create(:conversation, contact_inbox: contact_inbox, inbox: inbox, account: account, status: :resolved) }
  let(:service) { described_class.new(conversation: conversation) }

  describe '#perform' do
    let(:csat_template) { instance_double(MessageTemplates::Template::CsatSurvey) }

    before do
      allow(MessageTemplates::Template::CsatSurvey).to receive(:new).and_return(csat_template)
      allow(csat_template).to receive(:perform)
      allow(Conversations::ActivityMessageJob).to receive(:perform_later)
    end

    context 'when CSAT survey should be sent' do
      before do
        allow(conversation).to receive(:can_reply?).and_return(true)
      end

      it 'sends CSAT survey when within messaging window' do
        service.perform

        expect(MessageTemplates::Template::CsatSurvey).to have_received(:new).with(conversation: conversation)
        expect(csat_template).to have_received(:perform)
      end
    end

    context 'when outside messaging window' do
      before do
        allow(conversation).to receive(:can_reply?).and_return(false)
      end

      it 'creates activity message instead of sending survey' do
        service.perform

        expect(Conversations::ActivityMessageJob).to have_received(:perform_later).with(
          conversation,
          hash_including(content: I18n.t('conversations.activity.csat.not_sent_due_to_messaging_window'))
        )
        expect(MessageTemplates::Template::CsatSurvey).not_to have_received(:new)
      end
    end

    context 'when CSAT survey should not be sent' do
      it 'does nothing when conversation is not resolved' do
        conversation.update!(status: :open)

        service.perform

        expect(MessageTemplates::Template::CsatSurvey).not_to have_received(:new)
        expect(Conversations::ActivityMessageJob).not_to have_received(:perform_later)
      end

      it 'does nothing when CSAT survey is not enabled' do
        inbox.update!(csat_survey_enabled: false)

        service.perform

        expect(MessageTemplates::Template::CsatSurvey).not_to have_received(:new)
        expect(Conversations::ActivityMessageJob).not_to have_received(:perform_later)
      end

      it 'does nothing when CSAT already sent' do
        create(:message, conversation: conversation, content_type: :input_csat)

        service.perform

        expect(MessageTemplates::Template::CsatSurvey).not_to have_received(:new)
        expect(Conversations::ActivityMessageJob).not_to have_received(:perform_later)
      end

      it 'does nothing for Twitter conversations' do
        twitter_channel = create(:channel_twitter_profile)
        twitter_inbox = create(:inbox, channel: twitter_channel, csat_survey_enabled: true)
        twitter_conversation = create(:conversation,
                                      inbox: twitter_inbox,
                                      status: :resolved,
                                      additional_attributes: { type: 'tweet' })
        twitter_service = described_class.new(conversation: twitter_conversation)

        twitter_service.perform

        expect(MessageTemplates::Template::CsatSurvey).not_to have_received(:new)
        expect(Conversations::ActivityMessageJob).not_to have_received(:perform_later)
      end

      context 'when survey rules block sending' do
        before do
          inbox.update!(csat_config: {
                          'survey_rules' => {
                            'operator' => 'does_not_contain',
                            'values' => ['bot-detectado']
                          }
                        })
          conversation.update!(label_list: ['bot-detectado'])
        end

        it 'does not send CSAT' do
          service.perform

          expect(MessageTemplates::Template::CsatSurvey).not_to have_received(:new)
          expect(conversation.messages.where(content_type: :input_csat)).to be_empty
        end
      end
    end

    context 'when it is a WhatsApp channel' do
      let(:whatsapp_channel) do
        create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud',
                                  sync_templates: false, validate_provider_config: false)
      end
      let(:whatsapp_inbox) { create(:inbox, channel: whatsapp_channel, account: account, csat_survey_enabled: true) }
      let(:whatsapp_contact) { create(:contact, account: account) }
      let(:whatsapp_contact_inbox) { create(:contact_inbox, contact: whatsapp_contact, inbox: whatsapp_inbox, source_id: '1234567890') }
      let(:whatsapp_conversation) do
        create(:conversation, contact_inbox: whatsapp_contact_inbox, inbox: whatsapp_inbox, account: account, status: :resolved)
      end
      let(:whatsapp_service) { described_class.new(conversation: whatsapp_conversation) }
      let(:mock_provider_service) { instance_double(Whatsapp::Providers::WhatsappCloudService) }

      before do
        allow(Whatsapp::Providers::WhatsappCloudService).to receive(:new).and_return(mock_provider_service)
        allow(whatsapp_conversation).to receive(:can_reply?).and_return(true)
      end

      context 'when template is available and approved' do
        before do
          setup_approved_template('customer_survey_template')
        end

        it 'sends WhatsApp template survey instead of regular survey' do
          mock_successful_template_send('template_message_id_123')

          whatsapp_service.perform

          expect(mock_provider_service).to have_received(:send_template).with(
            '1234567890',
            hash_including(
              name: 'customer_survey_template',
              lang_code: 'en',
              parameters: array_including(
                hash_including(
                  type: 'button',
                  sub_type: 'url',
                  index: '0',
                  parameters: array_including(
                    hash_including(type: 'text', text: whatsapp_conversation.uuid)
                  )
                )
              )
            ),
            instance_of(Message)
          )
          expect(MessageTemplates::Template::CsatSurvey).not_to have_received(:new)
        end

        it 'updates message with returned message ID' do
          mock_successful_template_send('template_message_id_123')

          whatsapp_service.perform

          csat_message = whatsapp_conversation.messages.where(content_type: :input_csat).last
          expect(csat_message).to be_present
          expect(csat_message.source_id).to eq('template_message_id_123')
        end

        it 'builds correct template info with default template name' do
          expected_template_name = "customer_satisfaction_survey_#{whatsapp_inbox.id}"
          whatsapp_inbox.update!(csat_config: { 'template' => {}, 'message' => 'Rate us' })
          allow(mock_provider_service).to receive(:get_template_status)
            .with(expected_template_name)
            .and_return({ success: true, template: { status: 'APPROVED' } })
          allow(mock_provider_service).to receive(:send_template) do |_phone, _template, message|
            message.save!
            'msg_id'
          end

          whatsapp_service.perform

          expect(mock_provider_service).to have_received(:send_template).with(
            '1234567890',
            hash_including(
              name: expected_template_name,
              lang_code: 'en'
            ),
            anything
          )
        end

        it 'builds CSAT message with correct attributes' do
          allow(mock_provider_service).to receive(:send_template) do |_phone, _template, message|
            message.save!
            'msg_id'
          end

          whatsapp_service.perform

          csat_message = whatsapp_conversation.messages.where(content_type: :input_csat).last
          expect(csat_message.account).to eq(account)
          expect(csat_message.inbox).to eq(whatsapp_inbox)
          expect(csat_message.message_type).to eq('outgoing')
          expect(csat_message.content).to eq('Please rate your experience')
          expect(csat_message.content_type).to eq('input_csat')
        end

        it 'uses default message when not configured' do
          setup_approved_template('test', { 'template' => { 'name' => 'test' } })
          mock_successful_template_send('msg_id')

          whatsapp_service.perform

          csat_message = whatsapp_conversation.messages.where(content_type: :input_csat).last
          expect(csat_message.content).to eq('Please rate this conversation')
        end
      end

      context 'when template is not available or not approved' do
        it 'falls back to regular survey when template is pending' do
          setup_template_with_status('pending_template', 'PENDING')

          whatsapp_service.perform

          expect(MessageTemplates::Template::CsatSurvey).to have_received(:new).with(conversation: whatsapp_conversation)
          expect(csat_template).to have_received(:perform)
        end

        it 'falls back to regular survey when template is rejected' do
          setup_template_with_status('pending_template', 'REJECTED')

          whatsapp_service.perform

          expect(MessageTemplates::Template::CsatSurvey).to have_received(:new).with(conversation: whatsapp_conversation)
          expect(csat_template).to have_received(:perform)
        end

        it 'falls back to regular survey when template API call fails' do
          allow(mock_provider_service).to receive(:get_template_status)
            .with('pending_template')
            .and_return({ success: false, error: 'Template not found' })

          whatsapp_service.perform

          expect(MessageTemplates::Template::CsatSurvey).to have_received(:new).with(conversation: whatsapp_conversation)
          expect(csat_template).to have_received(:perform)
        end

        it 'falls back to regular survey when template status check raises error' do
          allow(mock_provider_service).to receive(:get_template_status)
            .and_raise(StandardError, 'API connection failed')

          whatsapp_service.perform

          expect(MessageTemplates::Template::CsatSurvey).to have_received(:new).with(conversation: whatsapp_conversation)
          expect(csat_template).to have_received(:perform)
        end
      end

      context 'when no template is configured' do
        it 'falls back to regular survey' do
          whatsapp_service.perform

          expect(MessageTemplates::Template::CsatSurvey).to have_received(:new).with(conversation: whatsapp_conversation)
          expect(csat_template).to have_received(:perform)
        end
      end

      context 'when template sending fails' do
        before do
          setup_approved_template('working_template', {
                                    'template' => { 'name' => 'working_template' },
                                    'message' => 'Rate us'
                                  })
        end

        it 'handles template sending errors gracefully' do
          mock_template_send_failure('Template send failed')

          expect { whatsapp_service.perform }.not_to raise_error

          # Should still create the CSAT message even if sending fails
          csat_message = whatsapp_conversation.messages.where(content_type: :input_csat).last
          expect(csat_message).to be_present
          expect(csat_message.source_id).to be_nil
        end

        it 'does not update message when send_template returns nil' do
          mock_template_send_with_no_id

          whatsapp_service.perform

          csat_message = whatsapp_conversation.messages.where(content_type: :input_csat).last
          expect(csat_message).to be_present
          expect(csat_message.source_id).to be_nil
        end
      end

      context 'when outside messaging window' do
        before do
          allow(whatsapp_conversation).to receive(:can_reply?).and_return(false)
        end

        it 'sends template survey even when outside messaging window if template is approved' do
          setup_approved_template('approved_template', { 'template' => { 'name' => 'approved_template' } })
          mock_successful_template_send('msg_id')

          whatsapp_service.perform

          expect(mock_provider_service).to have_received(:send_template)
          expect(MessageTemplates::Template::CsatSurvey).not_to have_received(:new)
          # No activity message should be created when template is successfully sent
        end

        it 'creates activity message when template is not available and outside window' do
          whatsapp_service.perform

          expect(Conversations::ActivityMessageJob).to have_received(:perform_later).with(
            whatsapp_conversation,
            hash_including(content: I18n.t('conversations.activity.csat.not_sent_due_to_messaging_window'))
          )
          expect(MessageTemplates::Template::CsatSurvey).not_to have_received(:new)
        end
      end

      context 'when survey rules block sending' do
        before do
          whatsapp_inbox.update!(csat_config: {
                                   'template' => { 'name' => 'customer_survey_template', 'language' => 'en' },
                                   'message' => 'Please rate your experience',
                                   'survey_rules' => {
                                     'operator' => 'does_not_contain',
                                     'values' => ['bot-detectado']
                                   }
                                 })
          whatsapp_conversation.update!(label_list: ['bot-detectado'])
        end

        it 'does not call WhatsApp template or create a CSAT message' do
          expect(mock_provider_service).not_to receive(:get_template_status)
          expect(mock_provider_service).not_to receive(:send_template)

          whatsapp_service.perform

          expect(whatsapp_conversation.messages.where(content_type: :input_csat)).to be_empty
        end
      end

      context 'when template has body variables' do
        before do
          whatsapp_inbox.update!(csat_config: {
                                   'template' => {
                                     'name' => 'customer_survey_template',
                                     'language' => 'en',
                                     'body_variables' => { '1' => '{{contact.name}}', '2' => 'static text' }
                                   },
                                   'message' => 'Hi {{1}}, {{2}}'
                                 })
          allow(mock_provider_service).to receive(:get_template_status)
            .with('customer_survey_template')
            .and_return({ success: true, template: { status: 'APPROVED' } })
        end

        it 'includes resolved body parameters in template payload' do
          allow(mock_provider_service).to receive(:send_template) do |_phone, template_info, message|
            message.save!
            body_component = template_info[:parameters].find { |p| p[:type] == 'body' }
            expect(body_component).to be_present
            expect(body_component[:parameters].length).to eq(2)
            expect(body_component[:parameters][0][:type]).to eq('text')
            expect(body_component[:parameters][0][:text]).to be_present
            expect(body_component[:parameters][1]).to eq({ type: 'text', text: 'static text' })
            'msg_id'
          end

          whatsapp_service.perform
        end

        it 'resolves liquid variables in CSAT message content' do
          mock_successful_template_send('msg_id')

          whatsapp_service.perform

          csat_message = whatsapp_conversation.messages.where(content_type: :input_csat).last
          expect(csat_message.content).to include('static text')
          expect(csat_message.content).not_to include('{{1}}')
          expect(csat_message.content).not_to include('{{2}}')
        end

        it 'falls back to original value in body parameters when liquid variable resolves to empty' do
          whatsapp_inbox.update!(csat_config: {
                                   'template' => {
                                     'name' => 'customer_survey_template',
                                     'language' => 'en',
                                     'body_variables' => { '1' => '{{contact.nonexistent_attr}}' }
                                   },
                                   'message' => 'Attr: {{1}}'
                                 })

          allow(mock_provider_service).to receive(:send_template) do |_phone, template_info, message|
            message.save!
            # The body parameter should contain the original liquid variable string as fallback
            body_component = template_info[:parameters].find { |p| p[:type] == 'body' }
            expect(body_component[:parameters][0][:text]).to eq('{{contact.nonexistent_attr}}')
            'msg_id'
          end

          whatsapp_service.perform
        end
      end

      context 'when template has no body variables' do
        before do
          whatsapp_inbox.update!(csat_config: {
                                   'template' => {
                                     'name' => 'customer_survey_template',
                                     'language' => 'en'
                                   },
                                   'message' => 'Please rate your experience'
                                 })
          allow(mock_provider_service).to receive(:get_template_status)
            .with('customer_survey_template')
            .and_return({ success: true, template: { status: 'APPROVED' } })
        end

        it 'does not include body parameters in template payload' do
          allow(mock_provider_service).to receive(:send_template) do |_phone, template_info, message|
            message.save!
            body_component = template_info[:parameters].find { |p| p[:type] == 'body' }
            expect(body_component).to be_nil
            'msg_id'
          end

          whatsapp_service.perform
        end
      end
    end
  end

  private

  def setup_approved_template(template_name, config = nil)
    template_config = config || {
      'template' => {
        'name' => template_name,
        'language' => 'en'
      },
      'message' => 'Please rate your experience'
    }
    whatsapp_inbox.update!(csat_config: template_config)
    allow(mock_provider_service).to receive(:get_template_status)
      .with(template_name)
      .and_return({ success: true, template: { status: 'APPROVED' } })
  end

  def setup_template_with_status(template_name, status)
    whatsapp_inbox.update!(csat_config: {
                             'template' => { 'name' => template_name }
                           })
    allow(mock_provider_service).to receive(:get_template_status)
      .with(template_name)
      .and_return({ success: true, template: { status: status } })
  end

  def mock_successful_template_send(message_id)
    allow(mock_provider_service).to receive(:send_template) do |_phone, _template, message|
      message.save!
      message_id
    end
  end

  def mock_template_send_failure(error_message = 'Template send failed')
    allow(mock_provider_service).to receive(:send_template) do |_phone, _template, message|
      message.save!
      raise StandardError, error_message
    end
  end

  def mock_template_send_with_no_id
    allow(mock_provider_service).to receive(:send_template) do |_phone, _template, message|
      message.save!
      nil
    end
  end
end
