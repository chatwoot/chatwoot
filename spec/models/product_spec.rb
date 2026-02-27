# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Product do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
  end

  describe 'validations' do
    subject { create(:product) }

    it { is_expected.to validate_presence_of(:title_en) }
    it { is_expected.to validate_uniqueness_of(:title_en).scoped_to(:account_id) }
    it { is_expected.to validate_presence_of(:price) }
    it { is_expected.to validate_numericality_of(:price).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:stock).is_greater_than_or_equal_to(0).allow_nil }
  end

  describe '#in_stock?' do
    it 'returns true when stock is sufficient' do
      product = build(:product, stock: 10)
      expect(product.in_stock?(5)).to be true
    end

    it 'returns false when stock is insufficient' do
      product = build(:product, stock: 2)
      expect(product.in_stock?(5)).to be false
    end

    it 'returns true when stock is nil (unlimited)' do
      product = build(:product, :unlimited_stock)
      expect(product.in_stock?(999)).to be true
    end
  end

  describe '#deduct_stock!' do
    it 'reduces stock by the given quantity' do
      product = create(:product, stock: 10)
      product.deduct_stock!(3)
      expect(product.reload.stock).to eq(7)
    end

    it 'raises an error when stock is insufficient' do
      product = create(:product, stock: 2)
      expect { product.deduct_stock!(5) }.to raise_error(RuntimeError)
    end
  end

  describe '#restore_stock!' do
    it 'increases stock by the given quantity' do
      product = create(:product, stock: 5)
      product.restore_stock!(3)
      expect(product.reload.stock).to eq(8)
    end

    it 'does nothing when stock is nil' do
      product = create(:product, :unlimited_stock)
      product.restore_stock!(3)
      expect(product.reload.stock).to be_nil
    end
  end
end
