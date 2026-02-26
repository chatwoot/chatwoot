# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderItem do
  describe 'associations' do
    it { is_expected.to belong_to(:order) }
    it { is_expected.to belong_to(:product) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:quantity) }
    it { is_expected.to validate_numericality_of(:quantity).is_greater_than(0) }
    it { is_expected.to validate_presence_of(:unit_price) }
    it { is_expected.to validate_numericality_of(:unit_price).is_greater_than(0) }
    it { is_expected.to validate_presence_of(:total_price) }
    it { is_expected.to validate_numericality_of(:total_price).is_greater_than(0) }

    describe 'product uniqueness per order' do
      let(:order) { create(:order) }
      let(:product) { create(:product, account: order.account) }

      it 'does not allow duplicate products in the same order' do
        create(:order_item, order: order, product: product)
        duplicate = build(:order_item, order: order, product: product)
        expect(duplicate).not_to be_valid
      end

      it 'allows the same product in different orders' do
        create(:order_item, order: order, product: product)
        other_order = create(:order, account: order.account)
        other_item = build(:order_item, order: other_order, product: product)
        expect(other_item).to be_valid
      end
    end
  end

  describe 'callbacks' do
    describe '#calculate_total_price' do
      it 'calculates total_price from unit_price and quantity' do
        order = create(:order)
        product = create(:product, account: order.account)
        item = order.order_items.build(product: product, unit_price: 15.50, quantity: 3, total_price: nil)
        item.valid?
        expect(item.total_price).to eq(46.50)
      end
    end
  end
end
