require 'rails_helper'

RSpec.describe SmartActionBuilder, type: :model do
  subject(:smart_action_builder) { described_class.new(conversation, params) }

  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:params) do
    ActionController::Parameters.new({
                                       name: 'Create a booking2',
                                       label: 'Create booking2',
                                       description: 'Sample Create booking',
                                       event: 'create_booking',
                                       intent_type: 'primary',
                                       message_id: '3',
                                       to: 'Booking Page',
                                       from: 'All Action',
                                       link: 'https:booking.link'
                                     })
  end

  describe '#perform' do
    it 'creates a new smart action' do
      expect { smart_action_builder.perform }.to change(SmartAction, :count).by(1)
    end

    it 'contains no error messages' do
      smart_action_builder.perform
      expect(smart_action_builder.errors).to eq([])
    end
  end
end
