# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Voice::Conference::Manager do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:channel) { create(:channel_twilio_sms, :with_voice, account: account, phone_number: '+15551239999') }
  let(:conversation) { create(:conversation, account: account, inbox: channel.inbox) }
  let(:call) { create(:call, conversation: conversation, status: 'in_progress', accepted_by_agent: agent, started_at: 1.minute.ago) }
  let(:conference) { instance_double(Voice::Provider::Twilio::ConferenceService, end_conference_unless_agents_remain: nil) }
  let(:agent_label) { "agent-#{agent.id}-account-#{account.id}" }

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new)
      .and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: "AP#{SecureRandom.hex(8)}"))
    allow(Voice::Provider::Twilio::ConferenceService).to receive(:new).and_return(conference)
  end

  def leave(label)
    described_class.new(call: call, event: 'leave', participant_label: label).process
  end

  describe 'an agent leg leaving a live call' do
    it 'completes the call and hangs up the contact unless another agent remains' do
      leave(agent_label)

      expect(call.reload.status).to eq('completed')
      expect(conference).to have_received(:end_conference_unless_agents_remain).with(leaving_label: agent_label)
    end

    it 'still completes the call when Twilio cannot be reached' do
      allow(conference).to receive(:end_conference_unless_agents_remain).and_raise(Twilio::REST::TwilioError)

      expect { leave(agent_label) }.not_to raise_error
      expect(call.reload.status).to eq('completed')
    end
  end

  describe 'the contact leaving' do
    it 'completes the call without touching the conference' do
      leave('contact')

      expect(call.reload.status).to eq('completed')
      expect(conference).not_to have_received(:end_conference_unless_agents_remain)
    end
  end

  describe 'an agent leg leaving while the call is still ringing' do
    it 'marks the call unanswered and leaves the conference to the other agents' do
      call.update!(status: 'in_progress')
      call.update!(status: 'ringing', accepted_by_agent: nil)

      leave(agent_label)

      expect(call.reload.status).to eq('no_answer')
      expect(conference).not_to have_received(:end_conference_unless_agents_remain)
    end
  end
end
