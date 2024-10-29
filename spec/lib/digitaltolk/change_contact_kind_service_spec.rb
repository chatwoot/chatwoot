require 'rails_helper'

RSpec.describe Digitaltolk::ChangeContactKindService do
  subject { described_class.new(account, conversation, contact_kind) }

  let(:account) { create(:account) }
  let(:conversation) { create(:conversation) }
  let(:contact_kind) { 1 }

  describe '#initialize' do
    context 'when contact_kind is a string' do
      it 'converts contact_kind string to integer' do
        service = described_class.new(account, conversation, 'tolk_contact')
        expect(service.instance_variable_get(:@contact_kind)).to eq(1)
      end
    end

    context 'when contact_kind is already an integer' do
      it 'does not modify contact_kind' do
        service = described_class.new(account, conversation, 2)
        expect(service.instance_variable_get(:@contact_kind)).to eq(2)
      end
    end

    context 'when contact_kind is a string that is not in KIND_LABELS' do
      it 'converts contact_kind string to integer' do
        service = described_class.new(account, conversation, 'new_contact')
        expect(service.instance_variable_get(:@contact_kind)).to eq(nil)
      end
    end

    context 'when contact_kind is coming from a custom attribute' do
      it 'converts contact_kind string to integer' do
        service = described_class.new(account, conversation, 'Tolk')
        expect(service.instance_variable_get(:@contact_kind)).to eq(1)
      end
    end
  end

  # describe '#initialize' do
  #   context 'when contact_kind is a string' do
  #     it 'converts contact_kind string to integer' do
  #       service = described_class.new(conversation: nil, contact_kind: 'tolk_contact')
  #       expect(service.instance_variable_get(:@contact_kind)).to eq(1)
  #     end
  #   end

  #   context 'when contact_kind is already an integer' do
  #     it 'does not modify contact_kind' do
  #       service = described_class.new(conversation: nil, contact_kind: 2)
  #       expect(service.instance_variable_get(:@contact_kind)).to eq(2)
  #     end
  #   end
  # end

  # describe '#perform' do
  #   it 'calls set_custom_attributes, toggle_contact_kind, and toggle_contact_kind_labels' do
  #     conversation = double('Conversation')
  #     service = described_class.new(conversation: conversation, contact_kind: 1)

  #     expect(service).to receive(:set_custom_attributes)
  #     expect(service).to receive(:toggle_contact_kind)
  #     expect(service).to receive(:toggle_contact_kind_labels)

  #     service.perform
  #   end
  # end

  # describe '#toggle_contact_kind_labels' do
  #   it 'updates conversation labels with the new contact kind label' do
  #     conversation = double('Conversation', cached_label_list_array: ['kund_contact'])
  #     service = described_class.new(conversation: conversation, contact_kind: 3)

  #     expect(conversation).to receive(:update_labels).with(['kund_contact', 'översättare_contact'])

  #     service.send(:toggle_contact_kind_labels)
  #   end

  #   it 'does not update conversation labels if contact_kind is blank' do
  #     conversation = double('Conversation', cached_label_list_array: ['kund_contact'])
  #     service = described_class.new(conversation: conversation, contact_kind: nil)

  #     expect(conversation).not_to receive(:update_labels)

  #     service.send(:toggle_contact_kind_labels)
  #   end
  # end

  # describe '#set_custom_attributes' do
  #   it 'calls Digitaltolk::ChangeContactTypeCustomAttributesService with the conversation and attrib' do
  #     conversation = double('Conversation')
  #     attrib = double('Attrib')
  #     service = described_class.new(conversation: conversation, contact_kind: 4)

  #     expect(Digitaltolk::ChangeContactTypeCustomAttributesService).to receive(:new).with(conversation, attrib).and_return(double('Service', perform: true))

  #     service.send(:set_custom_attributes)
  #   end
  # end

  # describe '#equivalent_attrib' do
  #   it 'returns the first part of the contact kind label capitalized' do
  #     service = described_class.new(conversation: nil, contact_kind: 5)

  #     expect(service.send(:equivalent_attrib)).to eq('Övrigt')
  #   end
  # end
end
