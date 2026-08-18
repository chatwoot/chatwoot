# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationRecord do
  let(:account) { create(:account) }
  let(:contact) { create(:contact, account: account) }

  describe 'MAX_TEXT_COLUMN_LENGTH' do
    it 'defaults to 20000' do
      expect(described_class::MAX_TEXT_COLUMN_LENGTH).to eq(20_000)
    end
  end

  describe '#validates_column_content_length' do
    context 'when content is within the configured limit' do
      it 'is valid' do
        note = build(:note, account: account, contact: contact, content: 'a' * described_class::MAX_TEXT_COLUMN_LENGTH)

        expect(note).to be_valid
      end
    end

    context 'when content exceeds the configured limit' do
      it 'adds an error' do
        note = build(:note, account: account, contact: contact, content: 'a' * (described_class::MAX_TEXT_COLUMN_LENGTH + 1))

        expect(note).not_to be_valid
        expect(note.errors[:content]).to include("is too long (maximum is #{described_class::MAX_TEXT_COLUMN_LENGTH} characters)")
      end
    end

    context 'when MAX_TEXT_COLUMN_LENGTH is configured via env' do
      it 'enforces the configured limit' do
        stub_const('ApplicationRecord::MAX_TEXT_COLUMN_LENGTH', 3)

        note = build(:note, account: account, contact: contact, content: 'a' * 4)

        expect(note).not_to be_valid
        expect(note.errors[:content]).to include('is too long (maximum is 3 characters)')
      end
    end
  end
end
