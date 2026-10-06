# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Channel::WebWidget do
  context 'when
  web widget channel' do
    let!(:channel_widget) { create(:channel_widget) }

    it 'pre chat options' do
      expect(channel_widget.pre_chat_form_options['pre_chat_message']).to eq 'Share your queries or comments here.'
      expect(channel_widget.pre_chat_form_options['pre_chat_fields'].length).to eq 3
    end
  end

  describe '#public_portal' do
    let(:channel_widget) { create(:channel_widget) }
    let(:portal) { create(:portal, account: channel_widget.account) }

    before { channel_widget.inbox.update!(portal: portal) }

    it 'returns the portal linked to the inbox' do
      expect(channel_widget.public_portal).to eq(portal)
    end

    it 'returns nil when the portal is password protected' do
      portal.update!(config: { visibility: 'password' }, password: 'opensesame1')

      expect(channel_widget.reload.public_portal).to be_nil
    end
  end
end
