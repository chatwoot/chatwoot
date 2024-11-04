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
end
