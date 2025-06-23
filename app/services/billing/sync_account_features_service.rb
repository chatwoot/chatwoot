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

      Rails.logger.info "All possible features: #{all_features}"
      Rails.logger.info "Features to be enabled for #{@plan_name}: #{enabled_features}"

      # Disable all possible features first to handle downgrades
      Rails.logger.info 'Disabling all features...'
      @account.disable_features(*all_features)
      Rails.logger.info "Features after disabling all: #{@account.enabled_features.keys}"

      # Enable only the features for the current plan
      Rails.logger.info "Enabling features for #{@plan_name} plan..."
      @account.enable_features(*enabled_features) if enabled_features.present?
      Rails.logger.info "Features after enabling plan features: #{@account.enabled_features.keys}"

      @account.save!
      Rails.logger.info 'Account saved successfully.'
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