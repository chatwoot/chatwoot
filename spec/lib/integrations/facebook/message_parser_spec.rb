# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Integrations::Facebook::MessageParser do
  describe '#reaction' do
    let(:payload) do
      {
        'messaging' => {
          'sender' => { 'id' => 'sender-id' },
          'recipient' => { 'id' => 'page-id' },
          'timestamp' => 1_772_452_164_516,
          'reaction' => {
            'mid' => 'message-id-to-react-to',
            'action' => 'react',
            'reaction' => 'like',
            'emoji' => '👍'
          }
        }
      }.to_json
    end

    it 'exposes Messenger reaction attributes' do
      parser = described_class.new(payload)

      expect(parser).to be_reaction
      expect(parser.reaction_mid).to eq('message-id-to-react-to')
      expect(parser.reaction_action).to eq('react')
      expect(parser.reaction_type).to eq('like')
      expect(parser.reaction_emoji).to eq('👍')
      expect(parser.sender_id).to eq('sender-id')
      expect(parser.recipient_id).to eq('page-id')
      expect(parser.time_stamp).to eq(1_772_452_164_516)
    end
  end
end
