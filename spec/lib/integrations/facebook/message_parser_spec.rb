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
      expect(parser).to have_attributes(
        reaction_mid: 'message-id-to-react-to',
        reaction_action: 'react',
        reaction_type: 'like',
        reaction_emoji: '👍',
        sender_id: 'sender-id',
        recipient_id: 'page-id',
        time_stamp: 1_772_452_164_516
      )
    end
  end
end
