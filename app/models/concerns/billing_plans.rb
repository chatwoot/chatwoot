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

    # Get limits for a specific plan
    def plan_limits(plan_name)
      available_plans.dig(plan_name, 'limits') || {}
    end

    # Get external price ID for a plan (payment provider agnostic)
    def plan_price_id(plan_name)
      available_plans.dig(plan_name, 'price_id')
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
  end
end