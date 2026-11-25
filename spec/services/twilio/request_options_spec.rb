require 'rails_helper'

# The ceiling for Twilio's Content API, and the call that pays for it most.
RSpec.describe Twilio::RequestOptions do
  let(:channel) { create(:channel_twilio_sms) }
  let(:client) { Twilio::CsatTemplateApiClient.new(channel) }

  # `CsatSurveyService` reads this before sending a survey, once per conversation
  # resolved, inside a job. A Twilio that accepts the connection and then stops answering
  # held a worker for a minute there, per conversation, and the caller reads the failure
  # as "not approved", so nothing on the screen ever said why the survey stopped going
  # out. The ceiling does not fix that reading; it bounds what it costs.
  it 'bounds the read the survey path depends on' do
    options = nil
    allow(HTTParty).to receive(:get) do |_url, **kwargs|
      options = kwargs
      instance_double(HTTParty::Response, success?: true, body: '{}')
    end

    client.fetch_approval_status('HX123')

    expect(options).to include(timeout: 10, max_retries: 0)
  end

  # A fence, not a checklist. One ceiling for this family, so the count is the count of
  # calls: a sixth call arriving without it fails here rather than in production.
  it 'puts every call to the Content API under the one ceiling' do
    source = File.read(Rails.root.join('app/services/twilio/csat_template_api_client.rb'))

    expect(source.scan(/HTTParty\.\w+/).size).to eq(5)
    expect(source.scan('TWILIO_REQUEST_OPTIONS').size).to eq(5)
  end
end
