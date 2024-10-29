require 'rails_helper'

RSpec.describe Digitaltolk::ChangeContactTypeCustomAttributesService do
  subject { described_class.new(conversation, contact_type) }

  let(:conversation) { create(:conversation) }
  let(:contact_type) { 'Kund' }

  describe '#perform' do
    it 'sets the custom attributes and updates the conversation' do
      expect(subject.perform).to be_truthy

      conversation.reload
      expect(conversation.custom_attributes[CustomAttributeDefinition::CONTACT_TYPE]).to eq(contact_type)
    end
  end
end
