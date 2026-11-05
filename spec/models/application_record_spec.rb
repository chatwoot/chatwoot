# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationRecord do
  describe 'MAX_TEXT_COLUMN_LENGTH' do
    it 'defaults to 20_000 characters' do
      expect(described_class::MAX_TEXT_COLUMN_LENGTH).to eq(20_000)
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

    it 'rejects text columns that exceed the configured MAX_TEXT_COLUMN_LENGTH' do
      stub_const('ApplicationRecord::MAX_TEXT_COLUMN_LENGTH', 100)

      article.content = 'a' * 101

      expect(article).not_to be_valid
      expect(article.errors[:content]).to include('is too long (maximum is 100 characters)')
    end

    it 'allows text columns within the configured MAX_TEXT_COLUMN_LENGTH' do
      stub_const('ApplicationRecord::MAX_TEXT_COLUMN_LENGTH', 100)

      article.content = 'a' * 100

      expect(article).to be_valid
    end
  end
end
