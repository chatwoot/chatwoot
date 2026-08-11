require 'rails_helper'

RSpec.describe MessageTemplates::HookExecutionService do
  let(:account) { create(:account, custom_attributes: { plan_name: 'startups' }) }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:conversation) { create(:conversation, inbox: inbox, account: account, contact: contact, status: :pending) }
  let(:assistant) { create(:captain_assistant, account: account) }

  before do
    create(:captain_inbox, captain_assistant: assistant, inbox: inbox)
  end

  context 'when captain assistant is configured' do
    context 'when within business hours' do
      before do
        inbox.update!(working_hours_enabled: true)
        inbox.working_hours.find_by(day_of_week: Time.current.in_time_zone(inbox.timezone).wday).update!(
          open_all_day: true,
          closed_all_day: false
        )
      end

      it 'keeps the legacy job arguments for Captain V1' do
        allow(Captain::Conversation::ResponseBuilderJob).to receive(:perform_later)

        create(:message, conversation: conversation, message_type: :incoming, account: account)

        expect(Captain::Conversation::ResponseBuilderJob).to have_received(:perform_later).with(conversation, assistant)
      end

      it 'passes the responding message id for Captain V2' do
        account.enable_features!(:captain_integration_v2)
        allow(Captain::Conversation::ResponseBuilderJob).to receive(:perform_later)

        message = create(:message, conversation: conversation, message_type: :incoming, account: account)

        expect(Captain::Conversation::ResponseBuilderJob).to have_received(:perform_later).with(conversation, assistant, message.id)
      end

      it 'does not lock or schedule a job for an email auto reply' do
        account.enable_features!(:captain_integration_v2)
        allow(Captain::Conversation::ResponseBuilderJob).to receive(:perform_later)

        customer_message = create(:message, conversation: conversation, message_type: :incoming, account: account)
        auto_reply = build(
          :message,
          conversation: conversation,
          message_type: :incoming,
          content_type: :incoming_email,
          content_attributes: { email: { auto_reply: true } },
          account: account
        )
        auto_reply.save!

        expect(Captain::Conversation::ResponseBuilderJob).to have_received(:perform_later).once
        expect(Captain::Conversation::ResponseBuilderJob).to have_received(:perform_later).with(conversation, assistant, customer_message.id)
        expect(conversation.messages.captain_response_triggering).to contain_exactly(customer_message)
        expect(conversation.messages.captain_response_triggering).not_to include(auto_reply)
      end
    end

    context 'when calculating attachment wait time' do
      let(:configured_job) { instance_double(ActiveJob::ConfiguredJob, perform_later: true) }

      before do
        allow(Captain::Conversation::ResponseBuilderJob).to receive(:set).and_return(configured_job)
      end

      it 'uses only the current message attachments for Captain V1' do
        create(:message, :with_attachment, conversation: conversation, message_type: :incoming, account: account)
        create(:message, :with_attachment, conversation: conversation, message_type: :incoming, account: account)

        expect(Captain::Conversation::ResponseBuilderJob).to have_received(:set).with(wait: 2.seconds).twice
        expect(Captain::Conversation::ResponseBuilderJob).not_to have_received(:set).with(wait: 3.seconds)
      end

      it 'recalculates the wait from recent burst attachments for Captain V2' do
        account.enable_features!(:captain_integration_v2)

        create(:message, :with_attachment, conversation: conversation, message_type: :incoming, account: account)
        create(:message, :with_attachment, conversation: conversation, message_type: :incoming, account: account)

        expect(Captain::Conversation::ResponseBuilderJob).to have_received(:set).with(wait: 2.seconds).once
        expect(Captain::Conversation::ResponseBuilderJob).to have_received(:set).with(wait: 3.seconds).once
      end
    end

    context 'when outside business hours' do
      before do
        inbox.update!(
          working_hours_enabled: true,
          out_of_office_message: 'We are currently closed'
        )
        inbox.working_hours.find_by(day_of_week: Time.current.in_time_zone(inbox.timezone).wday).update!(
          closed_all_day: true,
          open_all_day: false
        )
      end

      it 'schedules captain response job outside business hours (Captain always responds when configured)' do
        expect(Captain::Conversation::ResponseBuilderJob).to receive(:perform_later).with(conversation, assistant)

        create(:message, conversation: conversation, message_type: :incoming, account: account)
      end

      it 'performs captain handoff when quota is exceeded (OOO template will kick in after handoff)' do
        account.update!(
          limits: { 'captain_responses' => 100 },
          custom_attributes: account.custom_attributes.merge('captain_responses_usage' => 100)
        )

        create(:message, conversation: conversation, message_type: :incoming, account: account)

        expect(conversation.reload.status).to eq('open')
      end

      it 'does not send out of office message when Captain is handling' do
        out_of_office_service = instance_double(MessageTemplates::Template::OutOfOffice)
        allow(MessageTemplates::Template::OutOfOffice).to receive(:new).and_return(out_of_office_service)
        allow(out_of_office_service).to receive(:perform).and_return(true)

        create(:message, conversation: conversation, message_type: :incoming, account: account)

        expect(MessageTemplates::Template::OutOfOffice).not_to have_received(:new)
      end
    end

    context 'when business hours are not enabled' do
      before do
        inbox.update!(working_hours_enabled: false)
      end

      it 'schedules captain response job regardless of time' do
        expect(Captain::Conversation::ResponseBuilderJob).to receive(:perform_later).with(conversation, assistant)

        create(:message, conversation: conversation, message_type: :incoming, account: account)
      end

      it 'records a conversation outcome when captain V2 is enabled' do
        account.enable_features!('captain_integration_v2')

        expect do
          create(:message, conversation: conversation, message_type: :incoming, account: account)
        end.to change(ConversationOutcome, :count).by(1)

        expect(ConversationOutcome.last).to have_attributes(
          assistant: assistant,
          conversation: conversation
        )
      end

      it 'does not record a conversation outcome when captain V2 is disabled' do
        expect do
          create(:message, conversation: conversation, message_type: :incoming, account: account)
        end.not_to change(ConversationOutcome, :count)
      end
    end

    context 'when captain quota is exceeded within business hours' do
      before do
        inbox.update!(working_hours_enabled: true)
        inbox.working_hours.find_by(day_of_week: Time.current.in_time_zone(inbox.timezone).wday).update!(
          open_all_day: true,
          closed_all_day: false
        )

        account.update!(
          limits: { 'captain_responses' => 100 },
          custom_attributes: account.custom_attributes.merge('captain_responses_usage' => 100)
        )
      end

      it 'performs handoff within business hours when quota exceeded' do
        create(:message, conversation: conversation, message_type: :incoming, account: account)

        expect(conversation.reload.status).to eq('open')
      end

      it 'emits a usage limit handoff event' do
        expect(Captain::ConversationEvents).to receive(:handed_off)
          .with(conversation: conversation, assistant: assistant, source: 'usage_limit', reason_category: :usage_limit, at: kind_of(Time))

        create(:message, conversation: conversation, message_type: :incoming, account: account)
      end

      it 'records the handoff on the outcome when captain V2 is enabled' do
        account.enable_features!('captain_integration_v2')

        expect do
          create(:message, conversation: conversation, message_type: :incoming, account: account)
        end.to change(ConversationOutcome, :count).by(1)

        expect(ConversationOutcome.last).to have_attributes(
          handoff_reason_category: 'usage_limit',
          handoff_at: be_present
        )
      end

      it 'does not record an outcome when captain V2 is disabled' do
        expect do
          create(:message, conversation: conversation, message_type: :incoming, account: account)
        end.not_to change(ConversationOutcome, :count)
      end
    end
  end

  context 'when no captain assistant is configured' do
    before do
      CaptainInbox.where(inbox: inbox).destroy_all
    end

    it 'does not schedule captain response job' do
      expect(Captain::Conversation::ResponseBuilderJob).not_to receive(:perform_later)

      create(:message, conversation: conversation, message_type: :incoming, account: account)
    end
  end

  it 'does not schedule Captain for inbox bot integrations' do
    expect(Captain::Conversation::ResponseBuilderJob).not_to receive(:perform_later)
    agent_bot_inbox = create(:agent_bot_inbox, inbox: inbox, agent_bot: create(:agent_bot, account: account))
    create(:message, conversation: conversation, message_type: :incoming, account: account)

    agent_bot_inbox.destroy!
    create(:integrations_hook, :dialogflow, inbox: inbox, account: account)
    create(:message, conversation: conversation, message_type: :incoming, account: account)
  end

  context 'when conversation is not pending' do
    before do
      conversation.update!(status: :open)
    end

    it 'does not schedule captain response job' do
      expect(Captain::Conversation::ResponseBuilderJob).not_to receive(:perform_later)

      create(:message, conversation: conversation, message_type: :incoming, account: account)
    end

    it 'still records the conversation as eligible demand when captain V2 is enabled' do
      account.enable_features!('captain_integration_v2')

      expect do
        create(:message, conversation: conversation, message_type: :incoming, account: account)
      end.to change(ConversationOutcome, :count).by(1)
    end
  end

  context 'when the contact is inside the assistant audience' do
    before do
      assistant.update!(config: assistant.config.merge('audience' => {
                                                         'attribute_key' => 'country_code', 'filter_operator' => 'equal_to', 'values' => ['US']
                                                       }))
      contact.update!(additional_attributes: { 'country_code' => 'US' })
    end

    it 'schedules captain response job' do
      expect(Captain::Conversation::ResponseBuilderJob).to receive(:perform_later).with(conversation, assistant)

      create(:message, conversation: conversation, message_type: :incoming, account: account)
    end
  end

  context 'when the conversation stops matching the audience mid-conversation' do
    it 'still schedules captain response job for the pending conversation' do
      conversation
      assistant.update!(config: assistant.config.merge('audience' => {
                                                         'attribute_key' => 'country_code', 'filter_operator' => 'equal_to', 'values' => ['US']
                                                       }))
      contact.update!(additional_attributes: { 'country_code' => 'CA' })

      expect(Captain::Conversation::ResponseBuilderJob).to receive(:perform_later).with(conversation, assistant)

      create(:message, conversation: conversation, message_type: :incoming, account: account)
    end
  end

  context 'when the reply schedule stops matching mid-conversation' do
    before do
      inbox.update!(working_hours_enabled: true)
      inbox.working_hours.find_by(day_of_week: Time.current.in_time_zone(inbox.timezone).wday).update!(
        open_all_day: true,
        closed_all_day: false
      )
    end

    it 'still schedules captain response job when business hours end after captain took the conversation' do
      assistant.update!(config: assistant.config.merge('response_window' => 'business_hours'))
      conversation
      inbox.working_hours.find_by(day_of_week: Time.current.in_time_zone(inbox.timezone).wday).update!(
        open_all_day: false,
        closed_all_day: true
      )

      expect(Captain::Conversation::ResponseBuilderJob).to receive(:perform_later).with(conversation, assistant)

      create(:message, conversation: conversation, message_type: :incoming, account: account)
    end

    it 'still schedules captain response job when business hours begin after captain took the conversation' do
      assistant.update!(config: assistant.config.merge('response_window' => 'outside_business_hours'))
      inbox.working_hours.find_by(day_of_week: Time.current.in_time_zone(inbox.timezone).wday).update!(
        open_all_day: false,
        closed_all_day: true
      )
      conversation
      inbox.working_hours.find_by(day_of_week: Time.current.in_time_zone(inbox.timezone).wday).update!(
        open_all_day: true,
        closed_all_day: false
      )

      expect(Captain::Conversation::ResponseBuilderJob).to receive(:perform_later).with(conversation, assistant)

      create(:message, conversation: conversation, message_type: :incoming, account: account)
    end

    it 'still schedules captain response job when both audience and schedule stop matching' do
      assistant.update!(config: assistant.config.merge('response_window' => 'business_hours'))
      conversation
      assistant.update!(config: assistant.config.merge('audience' => {
                                                         'attribute_key' => 'country_code', 'filter_operator' => 'equal_to', 'values' => ['US']
                                                       }))
      contact.update!(additional_attributes: { 'country_code' => 'CA' })
      inbox.working_hours.find_by(day_of_week: Time.current.in_time_zone(inbox.timezone).wday).update!(
        open_all_day: false,
        closed_all_day: true
      )

      expect(Captain::Conversation::ResponseBuilderJob).to receive(:perform_later).with(conversation, assistant)

      create(:message, conversation: conversation, message_type: :incoming, account: account)
    end
  end

  context 'when message is outgoing' do
    it 'does not schedule captain response job' do
      expect(Captain::Conversation::ResponseBuilderJob).not_to receive(:perform_later)

      create(:message, conversation: conversation, message_type: :outgoing, account: account)
    end
  end

  context 'when greeting and out of office messages with Captain enabled' do
    context 'when conversation is pending (Captain is handling)' do
      before do
        conversation.update!(status: :pending)
      end

      it 'does not create greeting message in conversation' do
        inbox.update!(greeting_enabled: true, greeting_message: 'Hello! How can we help you?', enable_email_collect: false)

        expect do
          create(:message, conversation: conversation, message_type: :incoming, account: account)
        end.not_to(change { conversation.reload.messages.template.count })
      end

      it 'does not create out of office message in conversation' do
        inbox.update!(
          working_hours_enabled: true,
          out_of_office_message: 'We are currently closed',
          enable_email_collect: false
        )
        inbox.working_hours.find_by(day_of_week: Time.current.in_time_zone(inbox.timezone).wday).update!(
          closed_all_day: true,
          open_all_day: false
        )

        expect do
          create(:message, conversation: conversation, message_type: :incoming, account: account)
        end.not_to(change { conversation.reload.messages.template.count })
      end
    end

    context 'when conversation is open (transferred to agent)' do
      before do
        conversation.update!(status: :open)
      end

      it 'creates greeting message in conversation' do
        inbox.update!(greeting_enabled: true, greeting_message: 'Hello! How can we help you?', enable_email_collect: false)

        expect do
          create(:message, conversation: conversation, message_type: :incoming, account: account)
        end.to change { conversation.reload.messages.template.count }.by(1)

        greeting_message = conversation.reload.messages.template.last
        expect(greeting_message.content).to eq('Hello! How can we help you?')
      end

      it 'creates out of office message when outside business hours' do
        inbox.update!(
          working_hours_enabled: true,
          out_of_office_message: 'We are currently closed',
          enable_email_collect: false
        )
        inbox.working_hours.find_by(day_of_week: Time.current.in_time_zone(inbox.timezone).wday).update!(
          closed_all_day: true,
          open_all_day: false
        )

        expect do
          create(:message, conversation: conversation, message_type: :incoming, account: account)
        end.to change { conversation.reload.messages.template.count }.by(1)

        out_of_office_message = conversation.reload.messages.template.last
        expect(out_of_office_message.content).to eq('We are currently closed')
      end
    end
  end

  context 'when Captain is not configured' do
    before do
      CaptainInbox.where(inbox: inbox).destroy_all
    end

    it 'creates greeting message in conversation' do
      inbox.update!(greeting_enabled: true, greeting_message: 'Hello! How can we help you?', enable_email_collect: false)

      expect do
        create(:message, conversation: conversation, message_type: :incoming, account: account)
      end.to change { conversation.reload.messages.template.count }.by(1)

      greeting_message = conversation.reload.messages.template.last
      expect(greeting_message.content).to eq('Hello! How can we help you?')
    end

    it 'creates out of office message when outside business hours' do
      inbox.update!(
        working_hours_enabled: true,
        out_of_office_message: 'We are currently closed',
        enable_email_collect: false
      )
      inbox.working_hours.find_by(day_of_week: Time.current.in_time_zone(inbox.timezone).wday).update!(
        closed_all_day: true,
        open_all_day: false
      )

      expect do
        create(:message, conversation: conversation, message_type: :incoming, account: account)
      end.to change { conversation.reload.messages.template.count }.by(1)

      out_of_office_message = conversation.reload.messages.template.last
      expect(out_of_office_message.content).to eq('We are currently closed')
    end
  end

  context 'when conversation has a campaign' do
    let(:campaign) { create(:campaign, account: account) }
    let(:campaign_conversation) { create(:conversation, inbox: inbox, account: account, contact: contact, status: :pending, campaign: campaign) }

    it 'schedules captain response job for incoming messages on pending campaign conversations' do
      expect(Captain::Conversation::ResponseBuilderJob).to receive(:perform_later).with(campaign_conversation, assistant)

      create(:message, conversation: campaign_conversation, message_type: :incoming, account: account)
    end

    it 'does not send greeting template on campaign conversations' do
      inbox.update!(greeting_enabled: true, greeting_message: 'Hello! How can we help you?', enable_email_collect: false)

      greeting_service = instance_double(MessageTemplates::Template::Greeting)
      allow(MessageTemplates::Template::Greeting).to receive(:new).and_return(greeting_service)
      allow(greeting_service).to receive(:perform).and_return(true)

      create(:message, conversation: campaign_conversation, message_type: :incoming, account: account)

      expect(MessageTemplates::Template::Greeting).not_to have_received(:new)
    end

    it 'does not send out of office template on campaign conversations' do
      inbox.update!(working_hours_enabled: true, out_of_office_message: 'We are currently closed')
      inbox.working_hours.find_by(day_of_week: Time.current.in_time_zone(inbox.timezone).wday).update!(
        closed_all_day: true,
        open_all_day: false
      )

      out_of_office_service = instance_double(MessageTemplates::Template::OutOfOffice)
      allow(MessageTemplates::Template::OutOfOffice).to receive(:new).and_return(out_of_office_service)
      allow(out_of_office_service).to receive(:perform).and_return(true)

      create(:message, conversation: campaign_conversation, message_type: :incoming, account: account)

      expect(MessageTemplates::Template::OutOfOffice).not_to have_received(:new)
    end

    it 'does not send email collect template on campaign conversations' do
      contact.update!(email: nil)
      inbox.update!(enable_email_collect: true)

      email_collect_service = instance_double(MessageTemplates::Template::EmailCollect)
      allow(MessageTemplates::Template::EmailCollect).to receive(:new).and_return(email_collect_service)
      allow(email_collect_service).to receive(:perform).and_return(true)

      create(:message, conversation: campaign_conversation, message_type: :incoming, account: account)

      expect(MessageTemplates::Template::EmailCollect).not_to have_received(:new)
    end

    it 'does not send out of office template after handoff on campaign conversations when quota is exceeded' do
      account.update!(
        limits: { 'captain_responses' => 100 },
        custom_attributes: account.custom_attributes.merge('captain_responses_usage' => 100)
      )
      inbox.update!(
        working_hours_enabled: true,
        out_of_office_message: 'We are currently closed'
      )
      inbox.working_hours.find_by(day_of_week: Time.current.in_time_zone(inbox.timezone).wday).update!(
        closed_all_day: true,
        open_all_day: false
      )

      expect do
        create(:message, conversation: campaign_conversation, message_type: :incoming, account: account)
      end.not_to(change { campaign_conversation.messages.template.count })
    end
  end

  context 'when Captain quota is exceeded and handoff happens' do
    before do
      account.update!(
        limits: { 'captain_responses' => 100 },
        custom_attributes: account.custom_attributes.merge('captain_responses_usage' => 100)
      )
    end

    context 'when outside business hours' do
      before do
        inbox.update!(
          working_hours_enabled: true,
          out_of_office_message: 'We are currently closed. Please leave your email.',
          enable_email_collect: false
        )
        inbox.working_hours.find_by(day_of_week: Time.current.in_time_zone(inbox.timezone).wday).update!(
          closed_all_day: true,
          open_all_day: false
        )
      end

      it 'sends out of office message after handoff due to quota exceeded' do
        expect do
          create(:message, conversation: conversation, message_type: :incoming, account: account)
        end.to change { conversation.messages.template.count }.by(1)

        expect(conversation.reload.status).to eq('open')
        ooo_message = conversation.messages.template.last
        expect(ooo_message.content).to eq('We are currently closed. Please leave your email.')
      end
    end

    context 'when within business hours' do
      before do
        inbox.update!(
          working_hours_enabled: true,
          out_of_office_message: 'We are currently closed.',
          enable_email_collect: false
        )
        inbox.working_hours.find_by(day_of_week: Time.current.in_time_zone(inbox.timezone).wday).update!(
          open_all_day: true,
          closed_all_day: false
        )
      end

      it 'does not send out of office message after handoff' do
        expect do
          create(:message, conversation: conversation, message_type: :incoming, account: account)
        end.not_to(change { conversation.messages.template.count })

        expect(conversation.reload.status).to eq('open')
      end
    end
  end
end
