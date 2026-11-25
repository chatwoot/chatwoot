require 'rails_helper'

# The half that the operator actually sees: which of the two reasons reaches the log.
RSpec.describe CsatSurveyService do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_twilio_sms, :with_phone_number, medium: :whatsapp, account: account) }
  let(:conversation) do
    create(:conversation, account: account, inbox: channel.inbox, status: :resolved).tap do |record|
      record.inbox.update!(csat_survey_enabled: true,
                           csat_config: { 'template' => { 'content_sid' => 'HX123', 'name' => 'csat' } })
    end
  end

  it 'names the read it could not make, instead of leaving the messaging window to take the blame' do
    stub_request(:get, 'https://content.twilio.com/v1/Content/HX123').to_timeout
    allow(Rails.logger).to receive(:error)

    described_class.new(conversation: conversation).perform

    expect(Rails.logger).to have_received(:error).with(/could not be told whether its Twilio template is approved/)
  end

  it 'says nothing of the kind when Twilio answered that the template is not approved' do
    stub_request(:get, 'https://content.twilio.com/v1/Content/HX123').to_return(status: 404, body: '{}')
    allow(Rails.logger).to receive(:error)

    described_class.new(conversation: conversation).perform

    expect(Rails.logger).not_to have_received(:error).with(/could not be told whether/)
  end
end
