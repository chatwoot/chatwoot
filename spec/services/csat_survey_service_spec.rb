require 'rails_helper'

describe CsatSurveyService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account, csat_survey_enabled: true) }
  let(:conversation) { create(:conversation, inbox: inbox, account: account, status: :resolved) }
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
        conversation.update(status: :open)

        service.perform

        expect(MessageTemplates::Template::CsatSurvey).not_to have_received(:new)
        expect(Conversations::ActivityMessageJob).not_to have_received(:perform_later)
      end

      it 'does nothing when CSAT survey is not enabled' do
        inbox.update(csat_survey_enabled: false)

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
    end
  end
end
