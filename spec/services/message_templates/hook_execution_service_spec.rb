require 'rails_helper'

describe ::MessageTemplates::HookExecutionService do
  context 'when Greeting Message' do
    it 'doesnot calls ::MessageTemplates::Template::Greeting if greeting_message is empty' do
      contact = create(:contact, email: nil)
      conversation = create(:conversation, contact: contact)
      # ensure greeting hook is enabled
      conversation.inbox.update(greeting_enabled: true, enable_email_collect: true)

      email_collect_service = double

      allow(::MessageTemplates::Template::EmailCollect).to receive(:new).and_return(email_collect_service)
      allow(email_collect_service).to receive(:perform).and_return(true)
      allow(::MessageTemplates::Template::Greeting).to receive(:new)

      # described class gets called in message after commit
      message = create(:message, conversation: conversation)

      expect(::MessageTemplates::Template::Greeting).not_to have_received(:new)
      expect(::MessageTemplates::Template::EmailCollect).to have_received(:new).with(conversation: message.conversation)
      expect(email_collect_service).to have_received(:perform)
    end

    it 'will not call ::MessageTemplates::Template::CsatSurvey if its a tweet conversation' do
      twitter_channel = create(:channel_twitter_profile)
      twitter_inbox = create(:inbox, channel: twitter_channel)
      # ensure greeting hook is enabled and greeting_message is present
      twitter_inbox.update(greeting_enabled: true, greeting_message: 'Hi, this is a greeting message')

      conversation = create(:conversation, inbox: twitter_inbox, additional_attributes: { type: 'tweet' })
      greeting_service = double
      allow(::MessageTemplates::Template::Greeting).to receive(:new).and_return(greeting_service)
      allow(greeting_service).to receive(:perform).and_return(true)

      message = create(:message, conversation: conversation)
      expect(::MessageTemplates::Template::Greeting).not_to have_received(:new).with(conversation: message.conversation)
    end
  end

  context 'when it is a first message from web widget' do
    it 'calls ::MessageTemplates::Template::EmailCollect' do
      contact = create(:contact, email: nil)
      conversation = create(:conversation, contact: contact)

      # ensure greeting hook is enabled and greeting_message is present
      conversation.inbox.update(greeting_enabled: true, enable_email_collect: true, greeting_message: 'Hi, this is a greeting message')

      email_collect_service = double
      greeting_service = double
      allow(::MessageTemplates::Template::EmailCollect).to receive(:new).and_return(email_collect_service)
      allow(email_collect_service).to receive(:perform).and_return(true)
      allow(::MessageTemplates::Template::Greeting).to receive(:new).and_return(greeting_service)
      allow(greeting_service).to receive(:perform).and_return(true)

      # described class gets called in message after commit
      message = create(:message, conversation: conversation)

      expect(::MessageTemplates::Template::Greeting).to have_received(:new).with(conversation: message.conversation)
      expect(greeting_service).to have_received(:perform)
      expect(::MessageTemplates::Template::EmailCollect).to have_received(:new).with(conversation: message.conversation)
      expect(email_collect_service).to have_received(:perform)
    end

    it 'doesnot calls ::MessageTemplates::Template::EmailCollect when prechat form is enabled' do
      contact = create(:contact, email: nil)
      conversation = create(:conversation, contact: contact)

      # ensure prechat form is enabled
      conversation.inbox.channel.update(pre_chat_form_enabled: true)
      allow(::MessageTemplates::Template::EmailCollect).to receive(:new).and_return(true)

      # described class gets called in message after commit
      message = create(:message, conversation: conversation)

      expect(::MessageTemplates::Template::EmailCollect).not_to have_received(:new).with(conversation: message.conversation)
    end

    it 'doesnot calls ::MessageTemplates::Template::EmailCollect on campaign conversations' do
      contact = create(:contact, email: nil)
      conversation = create(:conversation, contact: contact, campaign: create(:campaign))

      allow(::MessageTemplates::Template::EmailCollect).to receive(:new).and_return(true)

      # described class gets called in message after commit
      message = create(:message, conversation: conversation)

      expect(::MessageTemplates::Template::EmailCollect).not_to have_received(:new).with(conversation: message.conversation)
    end

    it 'doesnot calls ::MessageTemplates::Template::EmailCollect when enable_email_collect form is disabled' do
      contact = create(:contact, email: nil)
      conversation = create(:conversation, contact: contact)

      conversation.inbox.update(enable_email_collect: false)
      # ensure prechat form is enabled
      conversation.inbox.channel.update(pre_chat_form_enabled: true)
      allow(::MessageTemplates::Template::EmailCollect).to receive(:new).and_return(true)

      # described class gets called in message after commit
      message = create(:message, conversation: conversation)

      expect(::MessageTemplates::Template::EmailCollect).not_to have_received(:new).with(conversation: message.conversation)
    end
  end

  context 'when CSAT Survey' do
    let(:csat_survey) { double }
    let(:conversation) { create(:conversation) }

    before do
      allow(::MessageTemplates::Template::CsatSurvey).to receive(:new).and_return(csat_survey)
      allow(csat_survey).to receive(:perform).and_return(true)
    end

    it 'calls ::MessageTemplates::Template::CsatSurvey when a conversation is resolved in an inbox with survey enabled' do
      conversation.inbox.update(csat_survey_enabled: true)

      conversation.resolved!

      expect(::MessageTemplates::Template::CsatSurvey).to have_received(:new).with(conversation: conversation)
      expect(csat_survey).to have_received(:perform)
    end

    it 'will not call ::MessageTemplates::Template::CsatSurvey when Csat is not enabled' do
      conversation.inbox.update(csat_survey_enabled: false)

      conversation.resolved!

      expect(::MessageTemplates::Template::CsatSurvey).not_to have_received(:new).with(conversation: conversation)
      expect(csat_survey).not_to have_received(:perform)
    end

    it 'will not call ::MessageTemplates::Template::CsatSurvey if its a tweet conversation' do
      twitter_channel = create(:channel_twitter_profile)
      twitter_inbox = create(:inbox, channel: twitter_channel)
      conversation = create(:conversation, inbox: twitter_inbox, additional_attributes: { type: 'tweet' })
      conversation.inbox.update(csat_survey_enabled: true)

      conversation.resolved!

      expect(::MessageTemplates::Template::CsatSurvey).not_to have_received(:new).with(conversation: conversation)
      expect(csat_survey).not_to have_received(:perform)
    end

    it 'will not call ::MessageTemplates::Template::CsatSurvey if another Csat was already sent' do
      conversation.inbox.update(csat_survey_enabled: true)
      conversation.messages.create!(message_type: 'outgoing', content_type: :input_csat, account: conversation.account, inbox: conversation.inbox)

      conversation.resolved!

      expect(::MessageTemplates::Template::CsatSurvey).not_to have_received(:new).with(conversation: conversation)
      expect(csat_survey).not_to have_received(:perform)
    end
  end

  context 'when it is after working hours' do
    it 'calls ::MessageTemplates::Template::OutOfOffice' do
      contact = create :contact
      conversation = create :conversation, contact: contact

      conversation.inbox.update(working_hours_enabled: true, out_of_office_message: 'We are out of office')
      conversation.inbox.working_hours.today.update!(closed_all_day: true)

      out_of_office_service = double

      allow(::MessageTemplates::Template::OutOfOffice).to receive(:new).and_return(out_of_office_service)
      allow(out_of_office_service).to receive(:perform).and_return(true)

      # described class gets called in message after commit
      message = create(:message, conversation: conversation)

      expect(::MessageTemplates::Template::OutOfOffice).to have_received(:new).with(conversation: message.conversation)
      expect(out_of_office_service).to have_received(:perform)
    end

    it 'will not call ::MessageTemplates::Template::OutOfOffice if its a tweet conversation' do
      twitter_channel = create(:channel_twitter_profile)
      twitter_inbox = create(:inbox, channel: twitter_channel)
      twitter_inbox.update(working_hours_enabled: true, out_of_office_message: 'We are out of office')

      conversation = create(:conversation, inbox: twitter_inbox, additional_attributes: { type: 'tweet' })

      out_of_office_service = double

      allow(::MessageTemplates::Template::OutOfOffice).to receive(:new).and_return(out_of_office_service)
      allow(out_of_office_service).to receive(:perform).and_return(false)

      message = create(:message, conversation: conversation)
      expect(::MessageTemplates::Template::OutOfOffice).not_to have_received(:new).with(conversation: message.conversation)
      expect(out_of_office_service).not_to receive(:perform)
    end
  end
end
