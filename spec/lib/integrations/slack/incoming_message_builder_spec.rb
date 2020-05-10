require 'rails_helper'

describe Integrations::Slack::IncomingMessageBuilder do
  let(:hook) { create(:integrations_hook) }
  let(:verification_params) {slack_url_verification_stub}

  describe '#perform' do
    context 'url verification' do 
      it 'return challenge code as response' do
        builder = Integrations::Slack::IncomingMessageBuilder.new(verification_params)
        response = builder.perform
        expect(response[:challenge]).to eql(verification_params[:challenge])  
      end 
    end
  end
end