# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Billing::SubscriptionStatuses do
  describe 'constants' do
    it 'defines Stripe subscription statuses' do
      expect(described_class::ACTIVE).to eq('active')
      expect(described_class::CANCELED).to eq('canceled')
      expect(described_class::INCOMPLETE).to eq('incomplete')
      expect(described_class::INCOMPLETE_EXPIRED).to eq('incomplete_expired')
      expect(described_class::PAST_DUE).to eq('past_due')
      expect(described_class::TRIALING).to eq('trialing')
      expect(described_class::UNPAID).to eq('unpaid')
      expect(described_class::PAUSED).to eq('paused')
    end

    it 'defines application-specific statuses' do
      expect(described_class::INACTIVE).to eq('inactive')
    end

    it 'defines status groups' do
      expect(described_class::PAID_STATUSES).to contain_exactly('active', 'trialing')
      expect(described_class::FAILED_PAYMENT_STATUSES).to contain_exactly('past_due', 'canceled', 'unpaid')
      expect(described_class::ALL_STRIPE_STATUSES).to contain_exactly(
        'active', 'canceled', 'incomplete', 'incomplete_expired',
        'past_due', 'trialing', 'unpaid', 'paused'
      )
    end

    it 'ensures constants are frozen' do
      expect(described_class::PAID_STATUSES).to be_frozen
      expect(described_class::FAILED_PAYMENT_STATUSES).to be_frozen
      expect(described_class::ALL_STRIPE_STATUSES).to be_frozen
    end
  end

  describe '.paid_status?' do
    it 'returns true for active status' do
      expect(described_class.paid_status?('active')).to be true
    end

    it 'returns true for trialing status' do
      expect(described_class.paid_status?('trialing')).to be true
    end

    it 'returns false for canceled status' do
      expect(described_class.paid_status?('canceled')).to be false
    end

    it 'returns false for past_due status' do
      expect(described_class.paid_status?('past_due')).to be false
    end

    it 'returns false for unpaid status' do
      expect(described_class.paid_status?('unpaid')).to be false
    end

    it 'returns false for incomplete status' do
      expect(described_class.paid_status?('incomplete')).to be false
    end

    it 'returns false for nil or empty string' do
      expect(described_class.paid_status?(nil)).to be false
      expect(described_class.paid_status?('')).to be false
    end

    it 'returns false for unknown status' do
      expect(described_class.paid_status?('unknown_status')).to be false
    end
  end

  describe '.failed_payment_status?' do
    it 'returns true for past_due status' do
      expect(described_class.failed_payment_status?('past_due')).to be true
    end

    it 'returns true for canceled status' do
      expect(described_class.failed_payment_status?('canceled')).to be true
    end

    it 'returns true for unpaid status' do
      expect(described_class.failed_payment_status?('unpaid')).to be true
    end

    it 'returns false for active status' do
      expect(described_class.failed_payment_status?('active')).to be false
    end

    it 'returns false for trialing status' do
      expect(described_class.failed_payment_status?('trialing')).to be false
    end

    it 'returns false for incomplete status' do
      expect(described_class.failed_payment_status?('incomplete')).to be false
    end

    it 'returns false for nil or empty string' do
      expect(described_class.failed_payment_status?(nil)).to be false
      expect(described_class.failed_payment_status?('')).to be false
    end

    it 'returns false for unknown status' do
      expect(described_class.failed_payment_status?('unknown_status')).to be false
    end
  end

  describe '.valid_stripe_status?' do
    it 'returns true for all valid Stripe statuses' do
      described_class::ALL_STRIPE_STATUSES.each do |status|
        expect(described_class.valid_stripe_status?(status)).to be true
      end
    end

    it 'returns false for application-specific statuses' do
      expect(described_class.valid_stripe_status?('inactive')).to be false
    end

    it 'returns false for nil or empty string' do
      expect(described_class.valid_stripe_status?(nil)).to be false
      expect(described_class.valid_stripe_status?('')).to be false
    end

    it 'returns false for unknown status' do
      expect(described_class.valid_stripe_status?('unknown_status')).to be false
    end

    it 'returns false for custom statuses' do
      expect(described_class.valid_stripe_status?('custom_status')).to be false
      expect(described_class.valid_stripe_status?('pending')).to be false
    end
  end

  describe 'edge cases and integration' do
    it 'ensures paid and failed payment statuses are mutually exclusive' do
      overlap = described_class::PAID_STATUSES & described_class::FAILED_PAYMENT_STATUSES
      expect(overlap).to be_empty
    end

    it 'ensures all status checking methods handle string inputs' do
      expect(described_class.paid_status?(:active)).to be false  # symbol should return false
      expect(described_class.failed_payment_status?(:canceled)).to be false  # symbol should return false
      expect(described_class.valid_stripe_status?(:active)).to be false  # symbol should return false
    end

    it 'handles case sensitivity' do
      expect(described_class.paid_status?('ACTIVE')).to be false
      expect(described_class.failed_payment_status?('CANCELED')).to be false
      expect(described_class.valid_stripe_status?('ACTIVE')).to be false
    end
  end

  describe 'status completeness' do
    it 'includes all documented Stripe subscription statuses' do
      # Based on Stripe documentation: https://stripe.com/docs/api/subscriptions/object#subscription_object-status
      documented_statuses = %w[
        active canceled incomplete incomplete_expired
        past_due trialing unpaid paused
      ]

      expect(described_class::ALL_STRIPE_STATUSES).to match_array(documented_statuses)
    end

    it 'ensures status groups are subsets of all Stripe statuses' do
      expect(described_class::PAID_STATUSES).to all(be_in(described_class::ALL_STRIPE_STATUSES))
      expect(described_class::FAILED_PAYMENT_STATUSES).to all(be_in(described_class::ALL_STRIPE_STATUSES))
    end
  end
end