# frozen_string_literal: true

module Billing
  # Service to synchronize account features and limits based on subscription plan
  # Ensures that account capabilities match the subscribed plan
  class SyncAccountFeaturesService
    include BillingPlans

    def initialize(account, plan_name)
      @account = account
      @plan_name = plan_name
    end

    def perform
      Rails.logger.info '---[SYNC ACCOUNT FEATURES SERVICE - PERFORM]---'
      Rails.logger.info "Account ID: #{@account.id}, Plan Name: #{@plan_name}"
      return failure_response('Invalid plan') unless self.class.plan_exists?(@plan_name)

      begin
        @account.transaction do
          Rails.logger.info 'Updating plan limits...'
          update_plan_limits
          Rails.logger.info 'Updating plan features...'
          update_plan_features
        end

        Rails.logger.info '---[SYNC ACCOUNT FEATURES SERVICE - COMPLETED]---'
        success_response
      rescue StandardError => e
        Rails.logger.error "Error in SyncAccountFeaturesService: #{e.message}"
        failure_response("Feature synchronization failed: #{e.message}")
      end
    end

    private

    def update_plan_limits
      limits = self.class.plan_limits(@plan_name)
      # Using -1 for unlimited
      @account.limits = {
        agents: limits['agents'],
        inboxes: limits['inboxes'],
        conversations: limits['conversations']
      }
      @account.save!
    end

    def update_plan_features
      Rails.logger.info '---[SYNC ACCOUNT FEATURES SERVICE - UPDATE PLAN FEATURES]---'
      all_features = self.class.all_features
      enabled_features = self.class.plan_features(@plan_name)
      current_features = @account.enabled_features.keys.map(&:to_s)

      Rails.logger.info "All possible features: #{all_features}"
      Rails.logger.info "Features to be enabled for #{@plan_name}: #{enabled_features}"
      Rails.logger.info "Currently enabled features: #{current_features}"

      # Calculate which features need to be disabled and enabled
      features_to_disable = current_features - enabled_features
      features_to_enable = enabled_features - current_features

      Rails.logger.info "Features to disable: #{features_to_disable}"
      Rails.logger.info "Features to enable: #{features_to_enable}"

      # Only make changes if necessary to avoid unnecessary updates
      if features_to_disable.any? || features_to_enable.any?
        # Apply changes atomically within a single save operation
        if features_to_disable.any?
          Rails.logger.info "Disabling features: #{features_to_disable}"
          @account.disable_features(*features_to_disable)
        end

        if features_to_enable.any?
          Rails.logger.info "Enabling features: #{features_to_enable}"
          @account.enable_features(*features_to_enable)
        end

        @account.save!
        Rails.logger.info "Features after update: #{@account.enabled_features.keys}"
      else
        Rails.logger.info 'No feature changes needed - account already has correct features'
      end

      Rails.logger.info 'Feature sync completed successfully.'
    end

    def success_response
      {
        success: true,
        message: "Account features synchronized successfully for plan: #{@plan_name}"
      }
    end

    def failure_response(message)
      {
        success: false,
        error: message
      }
    end
  end
end