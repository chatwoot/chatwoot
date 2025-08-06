# frozen_string_literal: true

require 'rails_helper'

# Load the lib file using Rails.root for a more robust path
require Rails.root.join('lib/billing/stripe_metadata_extractor')

RSpec.describe StripeMetadataExtractor do
  describe '.extract_product_metadata' do
    let(:price_id) { 'price_123' }
    let(:product_id) { 'prod_456' }
    let(:product_metadata) { { 'plan_name' => 'starter', 'features' => 'basic' } }

    let(:stripe_price) do
      double('Stripe::Price', id: price_id, product: product_id)
    end

    let(:stripe_product) do
      double('Stripe::Product', metadata: product_metadata)
    end

    context 'with hash-style subscription data' do
      let(:subscription_hash) do
        {
          'items' => {
            'data' => [
              {
                'price' => {
                  'id' => price_id
                }
              }
            ]
          }
        }
      end

      it 'extracts metadata successfully with logging' do
        allow(Stripe::Price).to receive(:retrieve).with(price_id).and_return(stripe_price)
        allow(Stripe::Product).to receive(:retrieve).with(product_id).and_return(stripe_product)

        expect(Rails.logger).to receive(:info).with('---[EXTRACT PRODUCT METADATA - START]---')
        expect(Rails.logger).to receive(:info).with("Extracting product metadata for price_id: #{price_id}")
        expect(Rails.logger).to receive(:info).with('Calling Stripe API to retrieve price information...')
        expect(Rails.logger).to receive(:info).with("Price retrieved: #{price_id}, product: #{product_id}")
        expect(Rails.logger).to receive(:info).with('Fetching product metadata separately...')
        expect(Rails.logger).to receive(:info).with("✅ Product metadata retrieved successfully: #{product_metadata.inspect}")
        expect(Rails.logger).to receive(:info).with("Metadata class: #{product_metadata.class}")
        expect(Rails.logger).to receive(:info).with('---[EXTRACT PRODUCT METADATA - SUCCESS]---')

        result = described_class.extract_product_metadata(subscription_hash)

        expect(result).to eq(product_metadata)
        expect(Stripe::Price).to have_received(:retrieve).with(price_id)
        expect(Stripe::Product).to have_received(:retrieve).with(product_id)
      end

      it 'extracts metadata without logging when disabled' do
        allow(Stripe::Price).to receive(:retrieve).with(price_id).and_return(stripe_price)
        allow(Stripe::Product).to receive(:retrieve).with(product_id).and_return(stripe_product)

        expect(Rails.logger).not_to receive(:info)

        result = described_class.extract_product_metadata(subscription_hash, with_logging: false)

        expect(result).to eq(product_metadata)
      end
    end

    context 'with object-style subscription data' do
      let(:price_double) { double('Price', id: price_id) }
      let(:items_data) { [double('Item', price: price_double)] }
      let(:items) { double('Items', data: items_data) }
      let(:subscription_object) { double('Stripe::Subscription', items: items) }

      it 'extracts metadata successfully' do
        allow(Stripe::Price).to receive(:retrieve).with(price_id).and_return(stripe_price)
        allow(Stripe::Product).to receive(:retrieve).with(product_id).and_return(stripe_product)

        result = described_class.extract_product_metadata(subscription_object, with_logging: false)

        expect(result).to eq(product_metadata)
      end
    end

    context 'when price_id is missing' do
      let(:subscription_without_price) { { 'items' => { 'data' => [] } } }

      it 'returns empty hash and logs warning' do
        allow(Stripe::Price).to receive(:retrieve)

        expect(Rails.logger).to receive(:info).with('---[EXTRACT PRODUCT METADATA - START]---')
        expect(Rails.logger).to receive(:info).with('Extracting product metadata for price_id: ')
        expect(Rails.logger).to receive(:warn).with('No price_id found, returning empty metadata')

        result = described_class.extract_product_metadata(subscription_without_price)

        expect(result).to eq({})
        expect(Stripe::Price).not_to have_received(:retrieve)
      end

      it 'returns empty hash without logging when disabled' do
        expect(Rails.logger).not_to receive(:warn)

        result = described_class.extract_product_metadata(subscription_without_price, with_logging: false)

        expect(result).to eq({})
      end
    end

    context 'when price_id is blank' do
      let(:subscription_with_blank_price) do
        {
          'items' => {
            'data' => [
              {
                'price' => {
                  'id' => ''
                }
              }
            ]
          }
        }
      end

      it 'returns empty hash and logs warning' do
        expect(Rails.logger).to receive(:warn).with('No price_id found, returning empty metadata')

        result = described_class.extract_product_metadata(subscription_with_blank_price)

        expect(result).to eq({})
      end
    end

    context 'when Stripe API raises StripeError' do
      let(:subscription_hash) do
        {
          'items' => {
            'data' => [
              {
                'price' => {
                  'id' => price_id
                }
              }
            ]
          }
        }
      end

      it 'handles StripeError gracefully with logging' do
        stripe_error = Stripe::StripeError.new('API rate limit exceeded')
        allow(Stripe::Price).to receive(:retrieve).with(price_id).and_raise(stripe_error)

        expect(Rails.logger).to receive(:info).with('---[EXTRACT PRODUCT METADATA - START]---')
        expect(Rails.logger).to receive(:info).with("Extracting product metadata for price_id: #{price_id}")
        expect(Rails.logger).to receive(:info).with('Calling Stripe API to retrieve price information...')
        expect(Rails.logger).to receive(:error).with('❌ Stripe API error in extract_product_metadata:')
        expect(Rails.logger).to receive(:error).with('  - Error message: API rate limit exceeded')
        expect(Rails.logger).to receive(:error).with("  - Error type: #{stripe_error.class}")
        expect(Rails.logger).to receive(:error).with('  - Returning empty hash and continuing processing')
        expect(Rails.logger).to receive(:info).with('---[EXTRACT PRODUCT METADATA - STRIPE ERROR HANDLED]---')

        result = described_class.extract_product_metadata(subscription_hash)

        expect(result).to eq({})
      end

      it 'handles StripeError without logging when disabled' do
        stripe_error = Stripe::StripeError.new('API rate limit exceeded')
        allow(Stripe::Price).to receive(:retrieve).with(price_id).and_raise(stripe_error)

        expect(Rails.logger).not_to receive(:error)

        result = described_class.extract_product_metadata(subscription_hash, with_logging: false)

        expect(result).to eq({})
      end
    end

    context 'when Stripe API raises StandardError' do
      let(:subscription_hash) do
        {
          'items' => {
            'data' => [
              {
                'price' => {
                  'id' => price_id
                }
              }
            ]
          }
        }
      end

      it 'handles StandardError gracefully with logging' do
        standard_error = StandardError.new('Network timeout')
        standard_error.set_backtrace(%w[line1 line2 line3 line4])
        allow(Stripe::Price).to receive(:retrieve).with(price_id).and_raise(standard_error)

        expect(Rails.logger).to receive(:info).with('---[EXTRACT PRODUCT METADATA - START]---')
        expect(Rails.logger).to receive(:info).with("Extracting product metadata for price_id: #{price_id}")
        expect(Rails.logger).to receive(:info).with('Calling Stripe API to retrieve price information...')
        expect(Rails.logger).to receive(:error).with('❌ Unexpected error in extract_product_metadata:')
        expect(Rails.logger).to receive(:error).with('  - Error message: Network timeout')
        expect(Rails.logger).to receive(:error).with("  - Error class: #{standard_error.class}")
        expect(Rails.logger).to receive(:error).with('  - Backtrace: line1\\nline2\\nline3')
        expect(Rails.logger).to receive(:info).with('---[EXTRACT PRODUCT METADATA - ERROR HANDLED]---')

        result = described_class.extract_product_metadata(subscription_hash)

        expect(result).to eq({})
      end
    end

    context 'when product has no metadata' do
      let(:subscription_hash) do
        {
          'items' => {
            'data' => [
              {
                'price' => {
                  'id' => price_id
                }
              }
            ]
          }
        }
      end

      let(:stripe_product_no_metadata) do
        double('Stripe::Product', metadata: nil)
      end

      it 'returns empty hash' do
        allow(Stripe::Price).to receive(:retrieve).with(price_id).and_return(stripe_price)
        allow(Stripe::Product).to receive(:retrieve).with(product_id).and_return(stripe_product_no_metadata)

        result = described_class.extract_product_metadata(subscription_hash, with_logging: false)

        expect(result).to eq({})
      end
    end

    context 'when product metadata is empty' do
      let(:subscription_hash) do
        {
          'items' => {
            'data' => [
              {
                'price' => {
                  'id' => price_id
                }
              }
            ]
          }
        }
      end

      let(:stripe_product_empty_metadata) do
        double('Stripe::Product', metadata: {})
      end

      it 'returns empty hash' do
        allow(Stripe::Price).to receive(:retrieve).with(price_id).and_return(stripe_price)
        allow(Stripe::Product).to receive(:retrieve).with(product_id).and_return(stripe_product_empty_metadata)

        result = described_class.extract_product_metadata(subscription_hash, with_logging: false)

        expect(result).to eq({})
      end
    end

    context 'edge cases with subscription structure' do
      it 'handles missing items key' do
        subscription = { 'other_data' => 'value' }

        result = described_class.extract_product_metadata(subscription, with_logging: false)

        expect(result).to eq({})
      end

      it 'handles missing data key' do
        subscription = { 'items' => { 'other_key' => 'value' } }

        result = described_class.extract_product_metadata(subscription, with_logging: false)

        expect(result).to eq({})
      end

      it 'handles empty data array' do
        subscription = { 'items' => { 'data' => [] } }

        result = described_class.extract_product_metadata(subscription, with_logging: false)

        expect(result).to eq({})
      end

      it 'handles missing price key in data' do
        subscription = { 'items' => { 'data' => [{ 'other_key' => 'value' }] } }

        result = described_class.extract_product_metadata(subscription, with_logging: false)

        expect(result).to eq({})
      end

      it 'handles nil subscription object with items method' do
        subscription = double('Subscription', items: nil)

        result = described_class.extract_product_metadata(subscription, with_logging: false)

        expect(result).to eq({})
      end
    end
  end

  describe 'private logging methods' do
    it 'delegates to Rails logger for info' do
      expect(Rails.logger).to receive(:info).with('test message')
      described_class.send(:log_info, 'test message')
    end

    it 'delegates to Rails logger for warn' do
      expect(Rails.logger).to receive(:warn).with('test warning')
      described_class.send(:log_warn, 'test warning')
    end

    it 'delegates to Rails logger for error' do
      expect(Rails.logger).to receive(:error).with('test error')
      described_class.send(:log_error, 'test error')
    end
  end
end