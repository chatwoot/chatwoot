# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LeadRetargeting::SendFollowUpService do
  let(:account) { create(:account) }
  let(:whatsapp_channel) { create(:channel_whatsapp, account: account) }
  let(:whatsapp_inbox) { create(:inbox, channel: whatsapp_channel, account: account) }
  let(:contact) { create(:contact, account: account, phone_number: '+1234567890') }
  let(:conversation) { create(:conversation, account: account, inbox: whatsapp_inbox, contact: contact) }
  let(:sequence) { create(:lead_follow_up_sequence, account: account, inbox: whatsapp_inbox) }
  let(:follow_up) do
    create(:conversation_follow_up,
           conversation: conversation,
           lead_follow_up_sequence: sequence,
           status: 'active',
           current_step: 0)
  end
  let(:service) { described_class.new(follow_up) }

  before do
    stub_request(:get, 'https://waba.360dialog.io/v1/configs/templates')
      .to_return(status: 200, body: {
        waba_templates: [
          {
            'name' => 'follow_up_message',
            'language' => 'en',
            'status' => 'APPROVED',
            'components' => [
              {
                'type' => 'BODY',
                'text' => 'Hello {{1}}, this is a follow-up message.'
              }
            ]
          },
          {
            'name' => 'test_template',
            'language' => 'es',
            'status' => 'APPROVED',
            'components' => [
              {
                'type' => 'BODY',
                'text' => 'Hola, este es un mensaje de prueba.'
              }
            ]
          }
        ]
      }.to_json, headers: { 'Content-Type' => 'application/json' })
    stub_request(:get, 'https://waba.360dialog.io/v1/settings/application')
      .to_return(status: 200, body: { settings: {} }.to_json, headers: { 'Content-Type' => 'application/json' })
    stub_request(:post, 'https://waba.360dialog.io/v1/configs/webhook')
      .to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  describe '#execute' do
    context 'when sequence is deactivated' do
      before { sequence.update!(active: false) }

      it 'cancels the follow-up' do
        service.execute
        expect(follow_up.reload.status).to eq('cancelled')
      end

      it 'stores cancellation reason' do
        service.execute
        expect(follow_up.reload.metadata['cancellation_reason']).to eq('Sequence deactivated')
      end
    end

    context 'when contact has replied recently' do
      before do
        sequence.update!(settings: sequence.settings.merge('stop_on_contact_reply' => true))
        # Create follow_up first to set its updated_at
        follow_up
        # Then create message after follow_up so it's considered recent
        create(:message, conversation: conversation, message_type: :incoming, created_at: Time.current)
      end

      it 'completes the follow-up' do
        service.execute
        expect(follow_up.reload.status).to eq('completed')
      end

      it 'stores completion reason' do
        service.execute
        expect(follow_up.reload.metadata['completion_reason']).to eq('Contact replied')
      end
    end

    context 'when conversation is resolved' do
      before do
        sequence.update!(settings: sequence.settings.merge('stop_on_conversation_resolved' => true))
        conversation.update!(status: :resolved)
      end

      it 'completes the follow-up' do
        service.execute
        expect(follow_up.reload.status).to eq('completed')
      end
    end

    context 'when all steps are completed' do
      before do
        sequence.update!(steps: [
                           {
                             'id' => 'step_1',
                             'type' => 'wait',
                             'enabled' => true,
                             'config' => { 'delay_value' => 1, 'delay_type' => 'hours' }
                           }
                         ])
        follow_up.update!(current_step: 1)
      end

      it 'completes the follow-up' do
        service.execute
        expect(follow_up.reload.status).to eq('completed')
      end

      it 'stores completion reason' do
        service.execute
        expect(follow_up.reload.metadata['completion_reason']).to eq('All steps completed')
      end
    end

    describe 'step execution' do
      context 'with wait step' do
        before do
          sequence.update!(steps: [
                             {
                               'id' => 'step_1',
                               'type' => 'wait',
                               'enabled' => true,
                               'config' => { 'delay_value' => 2, 'delay_type' => 'hours' }
                             },
                             {
                               'id' => 'step_2',
                               'type' => 'wait',
                               'enabled' => true,
                               'config' => { 'delay_value' => 1, 'delay_type' => 'days' }
                             }
                           ])
        end

        it 'advances to next step' do
          service.execute
          expect(follow_up.reload.current_step).to eq(1)
        end

        it 'sets next_action_at based on next step delay' do
          freeze_time do
            service.execute
            expect(follow_up.reload.next_action_at).to be_within(1.second).of(1.day.from_now)
          end
        end
      end

      context 'with add_label step' do
        let(:label_step) do
          {
            'id' => 'step_1',
            'type' => 'add_label',
            'enabled' => true,
            'config' => { 'labels' => ['urgent', 'follow_up'] }
          }
        end

        before do
          sequence.update!(steps: [label_step])
        end

        it 'adds labels to conversation' do
          service.execute
          expect(conversation.reload.label_list).to include('urgent', 'follow_up')
        end

        it 'completes the follow-up' do
          service.execute
          expect(follow_up.reload.status).to eq('completed')
          expect(follow_up.reload.metadata['completion_reason']).to eq('All steps completed')
        end
      end

      context 'with remove_label step' do
        let!(:label1) { create(:label, account: account, title: 'urgent') }
        let!(:label2) { create(:label, account: account, title: 'old') }
        let(:remove_step) do
          {
            'id' => 'step_1',
            'type' => 'remove_label',
            'enabled' => true,
            'config' => { 'labels' => ['old'] }
          }
        end

        before do
          conversation.add_labels([label1.title, label2.title])
          sequence.update!(steps: [remove_step])
        end

        it 'removes specified labels' do
          service.execute
          expect(conversation.reload.label_list).to include('urgent')
          expect(conversation.reload.label_list).not_to include('old')
        end
      end

      context 'with change_priority step' do
        let(:priority_step) do
          {
            'id' => 'step_1',
            'type' => 'change_priority',
            'enabled' => true,
            'config' => { 'priority' => 'urgent' }
          }
        end

        before do
          sequence.update!(steps: [priority_step])
          conversation.update!(priority: nil)
        end

        it 'changes conversation priority' do
          service.execute
          expect(conversation.reload.priority).to eq('urgent')
        end
      end
    end

    describe 'error handling' do
      before do
        sequence.update!(
          steps: [{
            'id' => 'step_1',
            'type' => 'send_template',
            'enabled' => true,
            'config' => {
              'template_name' => 'nonexistent',
              'language' => 'en'
            }
          }],
          settings: sequence.settings.merge('max_retries_per_step' => 2)
        )
      end

      context 'when step fails' do
        it 'schedules retry' do
          allow(service).to receive(:send_whatsapp_template).and_raise(StandardError.new('Template not found'))

          freeze_time do
            service.execute
            expect(follow_up.reload.next_action_at).to be > Time.current
          end
        end

        it 'increments retry count' do
          allow(service).to receive(:send_whatsapp_template).and_raise(StandardError.new('Template not found'))

          service.execute
          expect(follow_up.reload.metadata['retry_count']).to eq(1)
        end

        it 'stores error message' do
          allow(service).to receive(:send_whatsapp_template).and_raise(StandardError.new('Template not found'))

          service.execute
          expect(follow_up.reload.metadata['last_error']).to include('Template not found')
        end
      end

      context 'when max retries exceeded' do
        before do
          follow_up.update!(metadata: { 'retry_count' => 2 })
        end

        it 'marks as failed with skip fallback' do
          allow(service).to receive(:send_whatsapp_template).and_raise(StandardError.new('Template not found'))

          service.execute
          expect(follow_up.reload.current_step).to eq(1)  # Skipped to next step
        end
      end
    end

    describe 'variable rendering' do
      let(:contact) { create(:contact, account: account, name: 'John Doe', phone_number: '+1234567890') }
      let(:conversation) { create(:conversation, account: account, inbox: whatsapp_inbox, contact: contact) }

      it 'renders contact variables' do
        context = service.send(:build_variable_context)
        result = sequence.render_param_value('Hello {{contact.name}}!', context)
        expect(result).to eq('Hello John Doe!')
      end

      it 'renders conversation variables' do
        context = service.send(:build_variable_context)
        result = sequence.render_param_value('Conversation #{{conversation.display_id}}', context)
        expect(result).to eq("Conversation ##{conversation.display_id}")
      end

      it 'renders custom attributes' do
        contact.update!(custom_attributes: { 'city' => 'New York' })
        context = service.send(:build_variable_context)
        result = sequence.render_param_value('City: {{custom_attr.city}}', context)
        expect(result).to eq('City: New York')
      end
    end

    describe '#within_messaging_window?' do
      it 'calls MessageWindowService' do
        window_service = instance_double(Conversations::MessageWindowService)
        allow(Conversations::MessageWindowService).to receive(:new).with(conversation).and_return(window_service)
        allow(window_service).to receive(:can_reply?).and_return(true)

        expect(service.send(:within_messaging_window?)).to be true
      end
    end
  end
end
