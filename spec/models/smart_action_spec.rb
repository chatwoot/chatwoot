require 'rails_helper'

RSpec.describe SmartAction do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:conversation_id) }
    it { is_expected.to validate_presence_of(:message_id) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:message) }
    it { is_expected.to belong_to(:conversation) }
  end

  describe 'validates_factory' do
    it 'creates valid note object' do
      smart_action = create(:smart_action)
      expect(smart_action.name).to eq 'Create Booking'
    end
  end

  describe '#custom_attributes' do
    let(:to) { 'Booking Page' }
    let(:from) { 'Messages' }
    let(:link) { 'https://test.com' }

    it 'stores custom attributes correctly' do
      smart_action = create(:smart_action, to: to, from: from, link: link)
      expect(smart_action.to).to eq 'Booking Page'
      expect(smart_action.from).to eq 'Messages'
      expect(smart_action.link).to eq 'https://test.com'
    end
  end
end
