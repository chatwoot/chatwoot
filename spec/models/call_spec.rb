require 'rails_helper'

RSpec.describe Call do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:inbox) }
    it { is_expected.to belong_to(:conversation) }
    it { is_expected.to belong_to(:contact) }
    it { is_expected.to belong_to(:message).optional }
    it { is_expected.to belong_to(:accepted_by_agent).class_name('User').optional }
  end

  describe 'enums' do
    it 'pins the persisted provider values' do
      expect(described_class.providers).to eq({ 'twilio' => 0, 'whatsapp' => 1, 'pathors' => 2 })
    end

    it 'pins the persisted direction values' do
      expect(described_class.directions).to eq({ 'incoming' => 0, 'outgoing' => 1 })
    end
  end

  describe 'status validation' do
    it 'accepts every supported status' do
      Call::STATUSES.each do |status|
        expect(build(:call, status: status)).to be_valid
      end
    end

    it 'rejects an unknown status' do
      expect(build(:call, status: 'in-progress')).not_to be_valid
    end

    it 'flags the dashed display form as invalid on the way in' do
      call = build(:call, status: 'no-answer')
      call.valid?
      expect(call.errors[:status]).to be_present
    end
  end

  describe '#terminal?' do
    it 'is true for terminal statuses' do
      Call::TERMINAL_STATUSES.each do |status|
        expect(build(:call, status: status)).to be_terminal
      end
    end

    it 'is false for live statuses' do
      expect(build(:call, status: 'ringing')).not_to be_terminal
      expect(build(:call, status: 'in_progress')).not_to be_terminal
    end
  end

  describe '#display_status' do
    it 'maps underscored statuses to the dashed display form' do
      expect(build(:call, status: 'in_progress').display_status).to eq('in-progress')
      expect(build(:call, status: 'no_answer').display_status).to eq('no-answer')
    end

    it 'passes other statuses through untouched' do
      expect(build(:call, status: 'completed').display_status).to eq('completed')
      expect(build(:call, status: 'ringing').display_status).to eq('ringing')
    end
  end

  describe '#accepted_by_agent_name' do
    let(:conversation) { create(:conversation) }
    let(:agent) { create(:user, account: conversation.account, role: :agent) }

    it 'falls back to the Pathors AI label for pathors calls with no human answerer' do
      call = build(:call, :pathors, conversation: conversation)
      expect(call.accepted_by_agent_name).to eq('Pathors AI')
    end

    it 'returns nil for non-pathors calls with no human answerer' do
      expect(build(:call, conversation: conversation).accepted_by_agent_name).to be_nil
    end

    it 'prefers the accepting agent when one is set' do
      call = build(:call, :pathors, conversation: conversation, accepted_by_agent: agent)
      expect(call.accepted_by_agent_name).to eq(agent.available_name)
    end
  end

  describe 'meta backed attributes' do
    it 'stores from/to numbers and ended_at in the meta blob' do
      call = create(:call, :pathors, from_number: '+886912345678', to_number: '+886222222222')
      call.reload

      expect(call.from_number).to eq('+886912345678')
      expect(call.to_number).to eq('+886222222222')
      expect(call.meta['from_number']).to eq('+886912345678')
    end

    it 'normalises ended_at to iso8601' do
      call = build(:call, :pathors)
      call.ended_at = '2026-08-05T10:00:00Z'

      expect(call.ended_at).to eq(Time.zone.parse('2026-08-05T10:00:00Z').iso8601)
    end

    it 'nils out an unparseable ended_at' do
      call = build(:call, :pathors)
      call.ended_at = 'not-a-timestamp'

      expect(call.ended_at).to be_nil
    end
  end

  describe '#push_event_data' do
    let(:call) do
      create(:call, :pathors, status: 'in_progress', duration_seconds: 42, from_number: '+886912345678',
                              to_number: '+886222222222', started_at: Time.zone.parse('2026-08-05T10:00:00Z'))
    end

    it 'emits the display status and snake_case keys the bubble consumes' do
      data = call.push_event_data

      expect(data[:status]).to eq('in-progress')
      expect(data[:direction]).to eq('incoming')
      expect(data[:provider]).to eq('pathors')
      expect(data[:duration_seconds]).to eq(42)
      expect(data[:accepted_by_agent_name]).to eq('Pathors AI')
      expect(data[:from_number]).to eq('+886912345678')
    end

    it 'emits the shape-compat keys unset in P1' do
      data = call.push_event_data

      expect(data).to have_key(:conference_sid)
      expect(data[:conference_sid]).to be_nil
      expect(data).to have_key(:recording_url)
      expect(data[:recording_url]).to be_nil
    end

    it 'emits started_at as iso8601' do
      expect(call.push_event_data[:started_at]).to eq(Time.zone.parse('2026-08-05T10:00:00Z').iso8601)
    end
  end

  describe 'Message#push_event_data' do
    let(:conversation) { create(:conversation) }
    let(:message) { create(:message, conversation: conversation, account: conversation.account, content_type: 'voice_call') }

    it 'includes the call payload for voice_call messages' do
      call = create(:call, :pathors, conversation: conversation, message: message)

      expect(message.reload.push_event_data[:call]).to eq(call.push_event_data)
    end

    it 'omits the call key when the message has no call' do
      expect(message.push_event_data).not_to have_key(:call)
    end
  end
end
