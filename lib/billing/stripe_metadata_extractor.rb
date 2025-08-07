# frozen_string_literal: true

module Billing
  # Utility class for extracting product metadata from Stripe subscriptions
  # This avoids circular dependencies between billing services
  class StripeMetadataExtractor
    class << self
      # Extract product metadata from subscription
      # @param subscription [Stripe::Subscription, Hash] Stripe subscription object or hash
      # @param with_logging [Boolean] Whether to include detailed logging (default: true)
      # @return [Hash] Product metadata as a Ruby hash
      def extract_product_metadata(subscription, with_logging: true)
        log_info('---[EXTRACT PRODUCT METADATA - START]---') if with_logging

        price_id = if subscription.is_a?(Hash)
                     subscription.dig('items', 'data', 0, 'price', 'id')
                   else
                     subscription.items&.data&.first&.price&.id
                   end

        log_info("Extracting product metadata for price_id: #{price_id}") if with_logging

        if price_id.blank?
          log_warn('No price_id found, returning empty metadata') if with_logging
          return {}
        end

        begin
          log_info('Calling Stripe API to retrieve price information...') if with_logging

          # Fetch price object first without expand to avoid HTTP library issues
          price = ::Stripe::Price.retrieve(price_id)
          log_info("Price retrieved: #{price.id}, product: #{price.product}") if with_logging

          # Then fetch the product separately
          log_info('Fetching product metadata separately...') if with_logging
          product = ::Stripe::Product.retrieve(price.product)
          metadata = (product.metadata || {}).to_h

          if with_logging
            log_info("✅ Product metadata retrieved successfully: #{metadata.inspect}")
            log_info("Metadata class: #{metadata.class}")
            log_info('---[EXTRACT PRODUCT METADATA - SUCCESS]---')
          end

          metadata

        rescue ::Stripe::StripeError => e
          if with_logging
            log_error('❌ Stripe API error in extract_product_metadata:')
            log_error("  - Error message: #{e.message}")
            log_error("  - Error type: #{e.class}")
            log_error('  - Returning empty hash and continuing processing')
            log_info('---[EXTRACT PRODUCT METADATA - STRIPE ERROR HANDLED]---')
          end
          {}

        rescue StandardError => e
          if with_logging
            log_error('❌ Unexpected error in extract_product_metadata:')
            log_error("  - Error message: #{e.message}")
            log_error("  - Error class: #{e.class}")
            log_error("  - Backtrace: #{e.backtrace.first(3).join('\n')}")
            log_info('---[EXTRACT PRODUCT METADATA - ERROR HANDLED]---')
          end
          {}
        end
      end

      private

      def log_info(message)
        Rails.logger.info(message)
      end

      def log_warn(message)
        Rails.logger.warn(message)
      end

      def log_error(message)
        Rails.logger.error(message)
      end
    end
  end
end