require 'rails_helper'

# Three answers and not two: "Twilio says this template is not approved" and "we could not
# ask Twilio" used to be the same answer, and they are not the same fact. One is work for
# the operator, who has to sort the template out with Twilio; the other is transport,
# which fixes itself. Reading them as one thing is what made the timeline blame the
# messaging window for something the messaging window did not do.
RSpec.describe Twilio::CsatTemplateService do
  let(:channel) { create(:channel_twilio_sms, medium: :whatsapp, account_sid: 'AC1', auth_token: 'token') }
  let(:service) { described_class.new(channel) }
  let(:template_url) { 'https://content.twilio.com/v1/Content/HX123' }
  let(:approval_url) { 'https://content.twilio.com/v1/Content/HX123/ApprovalRequests' }

  it 'says the read did not happen when the request did not complete' do
    stub_request(:get, template_url).to_timeout

    result = service.get_template_status('HX123')

    expect(result).to include(success: false, unknown: true)
  end

  # A refusal is an answer. It must not be marked unknown, or the caller loses the one case
  # it can actually act on.
  it 'does not say that when Twilio answered and the template is not there' do
    stub_request(:get, template_url).to_return(status: 404, body: '{}')

    result = service.get_template_status('HX123')

    expect(result).to include(success: false)
    expect(result[:unknown]).to be_nil
  end

  it 'says nothing of the kind when it worked' do
    stub_request(:get, template_url).to_return(status: 200, body: { friendly_name: 'csat', language: 'en' }.to_json,
                                               headers: { 'Content-Type' => 'application/json' })
    stub_request(:get, approval_url).to_return(status: 200, body: { whatsapp: { name: 'csat', status: 'approved' } }.to_json,
                                               headers: { 'Content-Type' => 'application/json' })

    result = service.get_template_status('HX123')

    expect(result[:unknown]).to be_nil
    expect(result[:template][:status]).to eq('approved')
  end
end
