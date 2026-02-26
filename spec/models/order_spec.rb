# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Order do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:conversation) }
    it { is_expected.to belong_to(:contact) }
    it { is_expected.to belong_to(:created_by) }
    it { is_expected.to belong_to(:message).optional }
    it { is_expected.to have_many(:order_items).dependent(:destroy) }
    it { is_expected.to have_many(:products).through(:order_items) }
  end

  describe 'validations' do
    # external_payment_id presence/uniqueness can't be tested with shoulda matchers
    # because the before_validation callback auto-generates it
    it { is_expected.to validate_presence_of(:provider) }
    it { is_expected.to validate_presence_of(:subtotal) }
    it { is_expected.to validate_numericality_of(:subtotal).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_presence_of(:total) }
    it { is_expected.to validate_numericality_of(:total).is_greater_than(0) }
    it { is_expected.to validate_presence_of(:currency) }
    it { is_expected.to validate_presence_of(:account_id) }
    it { is_expected.to validate_presence_of(:conversation_id) }
    it { is_expected.to validate_presence_of(:contact_id) }
    it { is_expected.to validate_presence_of(:created_by_id) }
  end

  describe 'enums' do
    it {
      expect(described_class.statuses).to eq(
        'initiated' => 0,
        'pending' => 1,
        'paid' => 2,
        'failed' => 3,
        'expired' => 4,
        'cancelled' => 5
      )
    }
  end

  describe 'callbacks' do
    describe '#generate_external_payment_id' do
      it 'auto-generates external_payment_id when blank' do
        order = create(:order)
        order.external_payment_id = nil
        order.valid?
        expect(order.external_payment_id).to be_present
      end

      it 'does not overwrite existing external_payment_id' do
        order = create(:order, external_payment_id: 'CUSTOM123')
        expect(order.external_payment_id).to eq('CUSTOM123')
      end
    end

    describe '#calculate_totals' do
      it 'calculates subtotal and total from order items' do
        order = create(:order, subtotal: 0, total: 1)
        product = create(:product, account: order.account, price: 25.00)
        order.order_items.build(product: product, quantity: 2, unit_price: 25.00, total_price: 50.00)
        order.valid?
        expect(order.subtotal).to eq(50.00)
        expect(order.total).to eq(50.00)
      end
    end
  end

  describe '#mark_as_paid!' do
    it 'updates status to paid and merges callback data' do
      order = create(:order)
      order.mark_as_paid!({ transaction_id: 'TX123' })

      expect(order.reload.status).to eq('paid')
      expect(order.payload['payment_callback']).to include('transaction_id' => 'TX123')
      expect(order.payload['paid_at']).to be_present
    end
  end

  describe '#mark_as_failed!' do
    it 'updates status to failed and merges callback data' do
      order = create(:order)
      order.mark_as_failed!({ error: 'declined' })

      expect(order.reload.status).to eq('failed')
      expect(order.payload['payment_callback']).to include('error' => 'declined')
      expect(order.payload['failed_at']).to be_present
    end
  end

  describe '#mark_as_expired!' do
    it 'updates status to expired' do
      order = create(:order)
      order.mark_as_expired!

      expect(order.reload.status).to eq('expired')
      expect(order.payload['expired_at']).to be_present
    end
  end

  describe '#mark_as_cancelled!' do
    it 'updates status to cancelled and merges callback data' do
      order = create(:order)
      order.mark_as_cancelled!({ reason: 'customer_request' })

      expect(order.reload.status).to eq('cancelled')
      expect(order.payload['payment_callback']).to include('reason' => 'customer_request')
      expect(order.payload['cancelled_at']).to be_present
    end
  end

  describe '#paid_at' do
    it 'returns parsed time when paid_at exists in payload' do
      order = create(:order, :paid)
      expect(order.paid_at).to be_a(ActiveSupport::TimeWithZone)
    end

    it 'returns nil when paid_at is absent' do
      order = create(:order)
      expect(order.paid_at).to be_nil
    end
  end

  describe '#customer_data' do
    it 'returns customer_data from payload' do
      order = create(:order)
      expect(order.customer_data).to include('name' => 'Test Customer')
    end

    it 'returns empty hash when customer_data is absent' do
      order = create(:order, payload: {})
      expect(order.customer_data).to eq({})
    end
  end

  describe 'scopes' do
    describe '.by_status' do
      it 'filters orders by status' do
        paid_order = create(:order, :paid)
        create(:order, :failed)

        expect(described_class.by_status('paid')).to contain_exactly(paid_order)
      end
    end

    describe '.recent' do
      it 'orders by created_at desc' do
        old_order = create(:order, created_at: 2.days.ago)
        new_order = create(:order, created_at: 1.day.ago)

        expect(described_class.recent).to eq([new_order, old_order])
      end
    end

    describe '.search' do
      it 'searches by external_payment_id' do
        order = create(:order, external_payment_id: 'SEARCHME123')
        create(:order)

        expect(described_class.search('SEARCHME')).to contain_exactly(order)
      end

      it 'searches by contact name' do
        contact = create(:contact, name: 'John Doe')
        order = create(:order, contact: contact)
        create(:order)

        expect(described_class.search('John')).to contain_exactly(order)
      end
    end
  end

  describe '#restore_stock_on_terminal_status' do
    let(:account) { create(:account) }
    let(:product) { create(:product, account: account, stock: 10) }
    let(:order) { create(:order, account: account) }

    before do
      create(:order_item, order: order, product: product, quantity: 2)
    end

    it 'restores stock when order is cancelled' do
      order.update!(status: :cancelled)
      expect(product.reload.stock).to eq(12)
    end

    it 'restores stock when order is failed' do
      order.update!(status: :failed)
      expect(product.reload.stock).to eq(12)
    end

    it 'restores stock when order expires' do
      order.update!(status: :expired)
      expect(product.reload.stock).to eq(12)
    end
  end
end
