# frozen_string_literal: true

# BillingPlans module provides utilities for working with subscription plans
# defined in config/billing_plans.yml and features from config/features.yml
module BillingPlans
  extend ActiveSupport::Concern

  class_methods do
    # Load billing plans configuration from YAML file
    def billing_plans_config
      @billing_plans_config ||= YAML.load_file(Rails.root.join('config/billing_plans.yml'))
    end

    # Load features configuration from YAML file
    def features_config
      @features_config ||= YAML.load_file(Rails.root.join('config/features.yml'))
    end

    # Get all available plans
    def available_plans
      @available_plans ||= begin
        config_file = Rails.root.join('config/billing_plans.yml')
        plans_data = YAML.load_file(config_file)
        Rails.logger.info "Loaded billing plans from YAML: #{plans_data}"
        plans_data.with_indifferent_access['plans'] || {}
      rescue Errno::ENOENT
        Rails.logger.error 'billing_plans.yml not found.'
        {}
      end
    end

    # Get the default plan name
    def default_plan_name
      available_plans.find { |_k, v| v['default'] }.first || 'free'
    end

    # Get plan details by plan name
    def plan_details(plan_name)
      available_plans[plan_name.to_s]
    end

    # Get features for a specific plan (resolves tiers to actual features)
    def plan_features(plan_name)
      plan_data = available_plans[plan_name.to_s]
      return [] unless plan_data

      # If plan uses the old 'features' format, return it directly
      return plan_data['features'] if plan_data['features']

      # If plan uses the new 'feature_tiers' format, resolve features from tiers
      tiers = plan_data['feature_tiers'] || []
      resolve_features_from_tiers(tiers)
    end

    # Get features for specific tiers
    def resolve_features_from_tiers(tiers)
      return [] if tiers.empty?

      features_config.select do |feature|
        feature['tier'] && tiers.include?(feature['tier'])
      end.map { |feature| feature['name'] }
    end

    # Get all features for a specific tier
    def tier_features(tier_name)
      features_config.select { |feature| feature['tier'] == tier_name }.map { |feature| feature['name'] }
    end

    # Get all premium features (features that require paid plans)
    def premium_features
      paid_tiers = %w[starter professional enterprise]
      features_config.select do |feature|
        feature['tier'] && paid_tiers.include?(feature['tier'])
      end.map { |feature| feature['name'] }
    end

    # Get limits for a specific plan (with dynamic Stripe resolution)
    def plan_limits(plan_name)
      # Try dynamic resolution from Stripe first
      dynamic_limits = Billing::Providers::Stripe.get_plan_limits_from_stripe(plan_name)

      if dynamic_limits.present?
        Rails.logger.info "Using dynamic limits: #{dynamic_limits} for plan: #{plan_name}"
        return dynamic_limits
      end

      # Fallback to YAML configuration
      yaml_limits = available_plans.dig(plan_name, 'limits') || {}
      Rails.logger.info "Using YAML fallback limits: #{yaml_limits} for plan: #{plan_name}"

      yaml_limits
    end

    # Get external price ID for a plan (with dynamic Stripe resolution)
    def plan_price_id(plan_name)
      # Try dynamic resolution from Stripe first
      dynamic_price_id = Billing::Providers::Stripe.get_price_id_for_plan(plan_name)

      if dynamic_price_id.present?
        Rails.logger.info "Using dynamic price_id: #{dynamic_price_id} for plan: #{plan_name}"
        return dynamic_price_id
      end

      # Fallback to YAML configuration
      yaml_price_id = available_plans.dig(plan_name, 'price_id')
      Rails.logger.info "Using YAML fallback price_id: #{yaml_price_id} for plan: #{plan_name}"

      yaml_price_id
    end

    # Get complete plan data from Stripe (new method for enhanced functionality)
    def plan_data_from_stripe(plan_name)
      Billing::Providers::Stripe.get_plan_data_from_stripe(plan_name)
    end

    # Check if a plan exists
    def plan_exists?(plan_name)
      result = available_plans.key?(plan_name)
      Rails.logger.info "BillingPlans.plan_exists?(#{plan_name}) = #{result}"
      Rails.logger.info "Available plans: #{available_plans.keys}"
      result
    end

    # Get all plan names
    def plan_names
      available_plans.keys
    end

    # Get plan name by external price ID (payment provider agnostic)
    def plan_name_by_price_id(price_id)
      available_plans.find { |_name, details| details['price_id'] == price_id }&.first
    end

    # Get all features across all plans
    def all_features
      # Use both old and new format for backward compatibility
      legacy_features = available_plans.values.flat_map { |plan| plan['features'] }.compact
      tier_features = features_config.map { |feature| feature['name'] }.compact

      (legacy_features + tier_features).uniq
    end

    # Get available tiers
    def available_tiers
      %w[community free starter professional enterprise]
    end

    # Check if a feature is available in a specific tier
    def feature_in_tier?(feature_name, tier_name)
      tier_features(tier_name).include?(feature_name)
    end

    # Get the minimum tier required for a feature
    def minimum_tier_for_feature(feature_name)
      feature = features_config.find { |f| f['name'] == feature_name }
      feature&.dig('tier')
    end

    # Extract plan limits from billing provider metadata dynamically
    def limits_from_billing_provider_metadata(metadata)
      return {} if metadata.blank?

      # Defensive check: ensure metadata is a hash
      unless metadata.is_a?(Hash)
        Rails.logger.error "Expected metadata to be a Hash, got #{metadata.class}: #{metadata.inspect}"
        return {}
      end

      # Extract all keys ending with '_limit' and convert to limits format
      limits = {}
      metadata.each do |key, value|
        # Defensive checks for key and value types
        key_str = key.is_a?(Array) ? key.join('_') : key.to_s
        next unless key_str.end_with?('_limit')

        # Handle monthly vs overall limits based on naming convention
        limit_key = if key_str.end_with?('_monthly_limit')
                      # Convert 'conversations_monthly_limit' -> 'conversations_monthly'
                      key_str.gsub('_monthly_limit', '_monthly')
                    else
                      # Convert 'agents_limit' -> 'agents', 'inboxes_limit' -> 'inboxes', etc.
                      key_str.gsub('_limit', '')
                    end

        # Defensive value conversion
        value_int = if value.is_a?(Array)
                      value.first.to_i
                    else
                      value.to_i
                    end

        limits[limit_key] = value_int
      end

      limits
    end

    # Extract plan limits from YAML data dynamically
    def limits_from_yaml_data(plan_data)
      return {} if plan_data.blank? || plan_data['limits'].blank?

      # Return the limits hash from YAML, ensuring all values are integers
      plan_data['limits'].transform_values(&:to_i)
    end

    # Get plan details with billing provider metadata priority
    def plan_details_with_billing_provider_metadata(plan_name, billing_provider_metadata = nil)
      if billing_provider_metadata.present?
        yaml_details = plan_details(plan_name) || {}
        billing_provider_limits = limits_from_billing_provider_metadata(billing_provider_metadata)
        yaml_details.merge('limits' => billing_provider_limits)
      else
        plan_details(plan_name)
      end
    end

    # Get plan limits dynamically (works with billing provider metadata and YAML)
    def extract_plan_limits(plan_data_or_metadata, source_type = :yaml)
      case source_type
      when :billing_provider_metadata
        limits_from_billing_provider_metadata(plan_data_or_metadata)
      when :yaml
        limits_from_yaml_data(plan_data_or_metadata)
      else
        {}
      end
    end

    # Check if a limit is monthly (resets each billing period) or overall (cumulative)
    def monthly_limit?(limit_key)
      limit_key.to_s.end_with?('_monthly')
    end

    # Get the base limit name without the monthly suffix
    def base_limit_name(limit_key)
      limit_key.to_s.gsub('_monthly', '')
    end

    def validate_plan_limits_for_free_trial(plan_limits, plan_name)
      return unless plan_limits.blank? || plan_limits['conversations_monthly'].blank?

      Rails.logger.error "Missing required plan limits for free trial plan: #{plan_name}. Plan limits: #{plan_limits}"
      raise StandardError, "Plan configuration error: Missing conversations_monthly limit for plan '#{plan_name}'"
    end

    def validate_plan_limits_for_paid_plan(plan_limits, plan_name)
      required_limits = %w[agents inboxes]
      missing_limits = []

      if plan_limits.blank?
        missing_limits = required_limits + ['conversations_monthly or conversations']
      else
        # Check required limits
        required_limits.each do |limit|
          missing_limits << limit if plan_limits[limit].blank?
        end

        # Check conversations (either conversations_monthly or conversations is required)
        if plan_limits['conversations_monthly'].blank? && plan_limits['conversations'].blank?
          missing_limits << 'conversations_monthly or conversations'
        end
      end

      return if missing_limits.empty?

      Rails.logger.error "Missing required plan limits for plan: #{plan_name}. Missing: #{missing_limits.join(', ')}. Plan limits: #{plan_limits}"
      raise StandardError, "Plan configuration error: Missing required limits (#{missing_limits.join(', ')}) for plan '#{plan_name}'"
    end
  end
end