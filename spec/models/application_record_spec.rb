# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationRecord do
  describe '#max_text_column_length' do
    subject(:record) { Article.new }

    it 'defaults to 20_000 characters when unset' do
      with_modified_env MAX_TEXT_COLUMN_LENGTH: nil do
        expect(record.send(:max_text_column_length)).to eq(20_000)
      end
    end

    it 'parses a configured integer of at least 20_000' do
      with_modified_env MAX_TEXT_COLUMN_LENGTH: '25000' do
        expect(record.send(:max_text_column_length)).to eq(25_000)
      end
    end

    it 'rejects values below 20_000' do
      %w[100 19999].each do |value|
        with_modified_env MAX_TEXT_COLUMN_LENGTH: value do
          expect { record.send(:max_text_column_length) }.to raise_error(ArgumentError, /at least 20000/)
        end
      end
    end

    it 'rejects malformed values' do
      ['', '0', '-5', 'abc'].each do |value|
        with_modified_env MAX_TEXT_COLUMN_LENGTH: value do
          expect { record.send(:max_text_column_length) }.to raise_error(ArgumentError, /positive integer/)
        end
      end
    end
  end

  describe 'column content length validation' do
    let!(:account) { create(:account) }
    let(:user) { create(:user, account_ids: [account.id], role: :agent) }
    let!(:portal) { create(:portal, account_id: account.id, config: { allowed_locales: %w[en es] }) }
    let!(:category) { create(:category, slug: 'category_1', locale: 'en', portal_id: portal.id) }

    let(:article) do
      build(:article, category_id: category.id, author_id: user.id, portal_id: portal.id)
    end

    it 'rejects text columns that exceed the configured limit' do
      with_modified_env MAX_TEXT_COLUMN_LENGTH: '25000' do
        article.content = 'a' * 25_001

        expect(article).not_to be_valid
        expect(article.errors[:content]).to include('is too long (maximum is 25000 characters)')
      end
    end

    it 'allows text columns within the configured limit' do
      with_modified_env MAX_TEXT_COLUMN_LENGTH: '25000' do
        article.content = 'a' * 25_000

        expect(article).to be_valid
      end
    end
  end
end
