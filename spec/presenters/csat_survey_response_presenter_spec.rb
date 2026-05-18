require 'rails_helper'

RSpec.describe CsatSurveyResponsePresenter do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:contact) { conversation.contact }
  let(:agent) { create(:user, account: account) }
  let(:message) { create(:message, conversation: conversation, content_type: :input_csat) }
  let(:csat_survey_response) do
    create(:csat_survey_response,
           account: account,
           conversation: conversation,
           contact: contact,
           message: message,
           assigned_agent: agent,
           rating: 5,
           feedback_message: 'Excellent service!')
  end

  describe '#webhook_data' do
    subject(:webhook_data) { described_class.new(csat_survey_response, message).webhook_data }

    it 'includes the csat survey response id' do
      expect(webhook_data[:id]).to eq(csat_survey_response.id)
    end

    it 'includes the rating' do
      expect(webhook_data[:rating]).to eq(5)
    end

    it 'includes the feedback message' do
      expect(webhook_data[:feedback_message]).to eq('Excellent service!')
    end

    it 'includes conversation data' do
      expect(webhook_data[:conversation]).to include(
        id: conversation.id,
        display_id: conversation.display_id,
        inbox_id: conversation.inbox_id
      )
    end

    it 'includes contact data' do
      expect(webhook_data[:contact]).to include(
        id: contact.id,
        name: contact.name,
        email: contact.email
      )
    end

    it 'includes assigned agent data' do
      expect(webhook_data[:assigned_agent]).to include(
        id: agent.id,
        name: agent.name,
        email: agent.email
      )
    end

    it 'includes message id' do
      expect(webhook_data[:message_id]).to eq(message.id)
    end

    context 'when there is no assigned agent' do
      let(:csat_survey_response) do
        create(:csat_survey_response,
               account: account,
               conversation: conversation,
               contact: contact,
               message: message,
               assigned_agent: nil,
               rating: 5)
      end

      it 'returns nil for assigned_agent' do
        expect(webhook_data[:assigned_agent]).to be_nil
      end
    end
  end
end
