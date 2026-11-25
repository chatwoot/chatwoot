require 'rails_helper'

RSpec.describe Conversations::CsatSurveyRetryJob do
  subject(:job) { described_class.perform_later(conversation) }

  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account, csat_survey_enabled: true) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, status: :resolved) }

  # `low` has no worker in every deployment of this fork, so a job queued there would never run.
  it 'enqueues on a queue every deployment consumes' do
    expect { job }.to have_enqueued_job(described_class).on_queue('default')
  end

  it 'runs the survey service for the conversation' do
    service = instance_double(CsatSurveyService, perform: nil)
    allow(CsatSurveyService).to receive(:new).with(conversation: conversation).and_return(service)

    described_class.perform_now(conversation)

    expect(service).to have_received(:perform)
  end
end
