require 'rails_helper'

RSpec.describe Instagram::MessageId do
  let(:ids) { JSON.parse(Rails.root.join('spec/fixtures/instagram/unified_login_message_ids.json').read) }

  it 'recognizes the send and echo encodings of the same message in either direction' do
    expect(described_class.aliases(ids.fetch('first_send'))).to eq([ids.fetch('first_send'), ids.fetch('first_echo')])
    expect(described_class.aliases(ids.fetch('first_echo'))).to eq([ids.fetch('first_echo'), ids.fetch('first_send')])
  end

  it 'does not conflate different messages in the same thread' do
    expect(described_class.aliases(ids.fetch('first_echo'))).not_to include(ids.fetch('second_send'))
  end

  it 'leaves unrecognized and malformed provider IDs unchanged' do
    ['ordinary-mid', '', 'ZA', Base64.strict_encode64('ig_dm_item:2:IGMessageID:1:2:3')].each do |source_id|
      expect(described_class.aliases(source_id)).to eq([source_id])
    end
  end
end
