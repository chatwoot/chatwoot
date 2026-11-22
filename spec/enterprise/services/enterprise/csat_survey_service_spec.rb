require 'rails_helper'

RSpec.describe CsatSurveyService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account, csat_survey_enabled: true) }
  let(:conversation) { create(:conversation, inbox: inbox, account: account, status: :pending) }
  let(:csat_template) { instance_double(MessageTemplates::Template::CsatSurvey, perform: true) }

  before do
    allow(MessageTemplates::Template::CsatSurvey).to receive(:new).and_return(csat_template)
    create(:message, conversation: conversation, message_type: :incoming, content: 'Where is my order?')
    conversation.mark_captain_waiting_close
    conversation.update!(status: :resolved)
  end

  def perform_survey
    conversation.reload
    allow(conversation).to receive(:can_reply?).and_return(true)
    described_class.new(conversation: conversation).perform
  end

  it 'sends no survey when Captain resolved the conversation while waiting on the customer' do
    perform_survey

    expect(csat_template).not_to have_received(:perform)
  end

  it 'sends the survey when the conversation is resolved again after the customer replies' do
    travel 1.minute do
      create(:message, conversation: conversation.reload, message_type: :incoming, content: 'Here is my order number')
      conversation.reload.update!(status: :resolved)
    end

    perform_survey

    expect(csat_template).to have_received(:perform)
  end
end
