module Weave
  module Core
    class AdminAuditLog < ApplicationRecord
      self.table_name = 'weave_core_admin_audit_logs'
      
      belongs_to :master_admin, class_name: 'Weave::Core::MasterAdmin'
      belongs_to :account, class_name: 'Account', optional: true
      
      validates :action_type, presence: true
      validates :master_admin, presence: true
      
      scope :recent, -> { order(created_at: :desc) }
      scope :for_account, ->(account_id) { where(account_id: account_id) }
      scope :by_action, ->(action_type) { where(action_type: action_type) }
      scope :by_admin, ->(admin_id) { where(master_admin_id: admin_id) }
      
      ACTION_TYPES = %w[
        tenant_suspended
        tenant_reactivated
        subscription_upgraded
        subscription_downgraded
        benefit_granted
        benefit_revoked
        alert_acknowledged
        alert_resolved
        feature_toggled
        payment_issue_resolved
        integration_fixed
      ].freeze
      
      def action_details_parsed
        return {} if action_details.blank?
        JSON.parse(action_details)
      rescue JSON::ParserError
        {}
      end
      
      def action_details_parsed=(details_hash)
        self.action_details = details_hash.to_json
      end
      
      def action_type_display
        case action_type
        when 'tenant_suspended' then 'Tenant Suspended'
        when 'tenant_reactivated' then 'Tenant Reactivated'
        when 'subscription_upgraded' then 'Subscription Upgraded'
        when 'subscription_downgraded' then 'Subscription Downgraded'
        when 'benefit_granted' then 'Benefit Granted'
        when 'benefit_revoked' then 'Benefit Revoked'
        when 'alert_acknowledged' then 'Alert Acknowledged'
        when 'alert_resolved' then 'Alert Resolved'
        when 'feature_toggled' then 'Feature Toggled'
        when 'payment_issue_resolved' then 'Payment Issue Resolved'
        when 'integration_fixed' then 'Integration Fixed'
        else action_type.humanize
        end
      end
      
      def summary
        details = action_details_parsed
        
        case action_type
        when 'tenant_suspended'
          "Suspended account #{account&.name} (ID: #{account_id}) - Reason: #{reason || 'Not specified'}"
        when 'tenant_reactivated'
          "Reactivated account #{account&.name} (ID: #{account_id})"
        when 'benefit_granted'
          "Granted #{details['benefit_type']} to #{account&.name} - #{details['description']}"
        when 'subscription_upgraded'
          "Force upgraded #{account&.name} from #{details['old_plan']} to #{details['new_plan']}"
        else
          "#{action_type_display} for #{account&.name || 'System'}"
        end
      end
      
      def self.log_action!(admin, action_type, account: nil, resource_type: nil, resource_id: nil, action_details: {}, reason: nil, ip_address: nil)
        create!(
          master_admin: admin,
          account: account,
          action_type: action_type,
          resource_type: resource_type,
          resource_id: resource_id,
          action_details: action_details.to_json,
          reason: reason,
          ip_address: ip_address
        )
      end
      
      def self.recent_activity(limit = 50)
        recent.limit(limit).includes(:master_admin, :account)
      end
      
      def self.activity_stats(days = 30)
        since = days.days.ago
        
        {
          total_actions: where('created_at >= ?', since).count,
          actions_by_type: where('created_at >= ?', since).group(:action_type).count,
          actions_by_admin: where('created_at >= ?', since).joins(:master_admin).group('weave_core_master_admins.name').count,
          daily_activity: where('created_at >= ?', since).group("DATE(created_at)").count
        }
      end
    end
  end
end