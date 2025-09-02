module Weave
  module Core
    class TenantBenefit < ApplicationRecord
      self.table_name = 'weave_core_tenant_benefits'
      
      belongs_to :account, class_name: 'Account'
      belongs_to :granted_by, class_name: 'Weave::Core::MasterAdmin'
      
      validates :benefit_type, presence: true
      validates :account, presence: true
      validates :granted_by, presence: true
      
      scope :active, -> { where(active: true) }
      scope :expired, -> { where('expires_at <= ?', Time.current) }
      scope :unexpired, -> { where('expires_at > ? OR expires_at IS NULL', Time.current) }
      scope :by_type, ->(type) { where(benefit_type: type) }
      
      BENEFIT_TYPES = %w[
        extended_trial
        free_upgrade
        feature_unlock
        usage_bonus
        support_priority
        payment_extension
        custom_integration
        beta_access
      ].freeze
      
      def benefit_value_parsed
        return nil if benefit_value.blank?
        
        case benefit_type
        when 'extended_trial'
          benefit_value.to_i # days
        when 'free_upgrade'
          benefit_value # plan name
        when 'feature_unlock'
          JSON.parse(benefit_value) # array of feature names
        when 'usage_bonus'
          JSON.parse(benefit_value) # hash with bonus amounts
        else
          benefit_value
        end
      rescue JSON::ParserError
        benefit_value
      end
      
      def benefit_value_parsed=(value)
        case benefit_type
        when 'feature_unlock', 'usage_bonus'
          self.benefit_value = value.to_json
        else
          self.benefit_value = value.to_s
        end
      end
      
      def expired?
        expires_at.present? && expires_at <= Time.current
      end
      
      def active_and_valid?
        active? && !expired?
      end
      
      def days_until_expiry
        return nil unless expires_at
        return 0 if expired?
        
        ((expires_at - Time.current) / 1.day).ceil
      end
      
      def benefit_type_display
        case benefit_type
        when 'extended_trial' then 'Extended Trial'
        when 'free_upgrade' then 'Free Plan Upgrade'
        when 'feature_unlock' then 'Feature Unlock'
        when 'usage_bonus' then 'Usage Bonus'
        when 'support_priority' then 'Priority Support'
        when 'payment_extension' then 'Payment Extension'
        when 'custom_integration' then 'Custom Integration'
        when 'beta_access' then 'Beta Feature Access'
        else benefit_type.humanize
        end
      end
      
      def benefit_description
        return description if description.present?
        
        case benefit_type
        when 'extended_trial'
          "Trial extended by #{benefit_value_parsed} days"
        when 'free_upgrade'
          "Free upgrade to #{benefit_value_parsed} plan"
        when 'feature_unlock'
          "Unlocked features: #{benefit_value_parsed.join(', ')}"
        when 'usage_bonus'
          bonus = benefit_value_parsed
          "Bonus: #{bonus.map { |k, v| "#{v} #{k}" }.join(', ')}"
        when 'support_priority'
          'Priority customer support queue'
        when 'payment_extension'
          "Payment deadline extended by #{benefit_value_parsed} days"
        else
          benefit_type_display
        end
      end
      
      def apply_benefit!
        return false unless active_and_valid?
        
        case benefit_type
        when 'extended_trial'
          apply_extended_trial!
        when 'free_upgrade'
          apply_free_upgrade!
        when 'feature_unlock'
          apply_feature_unlock!
        else
          # Some benefits are passive and don't need application
          true
        end
      end
      
      def revoke!(admin, reason = nil)
        update!(active: false)
        
        # Log the revocation
        admin.log_action!(
          'benefit_revoked',
          account: account,
          resource_type: 'tenant_benefit',
          resource_id: id.to_s,
          action_details: {
            benefit_type: benefit_type,
            original_value: benefit_value,
            description: description
          },
          reason: reason
        )
        
        true
      end
      
      private
      
      def apply_extended_trial!
        subscription = account.weave_core_account_subscription
        return false unless subscription&.trial?
        
        additional_days = benefit_value_parsed
        subscription.extend_trial!(additional_days)
      end
      
      def apply_free_upgrade!
        subscription_service = Weave::Core::SubscriptionService.new(account)
        target_plan = benefit_value_parsed
        
        begin
          subscription_service.change_plan!(target_plan)
          true
        rescue => e
          Rails.logger.error "[TenantBenefit] Failed to apply free upgrade: #{e.message}"
          false
        end
      end
      
      def apply_feature_unlock!
        features_to_unlock = benefit_value_parsed
        return false unless features_to_unlock.is_a?(Array)
        
        features_to_unlock.each do |feature_name|
          toggle = Weave::Core::FeatureToggle.find_or_initialize_by(
            account: account,
            feature_key: feature_name
          )
          toggle.enabled = true
          toggle.save!
        end
        
        true
      end
      
      public
      
      def self.grant_benefit!(account, admin, benefit_type, benefit_value, description: nil, expires_at: nil, grant_reason: nil)
        benefit = create!(
          account: account,
          granted_by: admin,
          benefit_type: benefit_type,
          benefit_value: benefit_value,
          description: description,
          expires_at: expires_at,
          grant_reason: grant_reason,
          active: true
        )
        
        # Log the grant
        admin.log_action!(
          'benefit_granted',
          account: account,
          resource_type: 'tenant_benefit',
          resource_id: benefit.id.to_s,
          action_details: {
            benefit_type: benefit_type,
            benefit_value: benefit_value,
            description: description,
            expires_at: expires_at&.iso8601
          },
          reason: grant_reason
        )
        
        # Try to apply the benefit immediately
        benefit.apply_benefit!
        
        benefit
      end
      
      def self.cleanup_expired!
        expired.where(active: true).update_all(active: false)
      end
      
      def self.active_for_account(account)
        active.unexpired.where(account: account)
      end
      
      def self.has_benefit?(account, benefit_type)
        active_for_account(account).by_type(benefit_type).exists?
      end
    end
  end
end