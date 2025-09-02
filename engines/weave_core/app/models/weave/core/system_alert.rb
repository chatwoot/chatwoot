module Weave
  module Core
    class SystemAlert < ApplicationRecord
      self.table_name = 'weave_core_system_alerts'
      
      belongs_to :account, class_name: 'Account', optional: true
      belongs_to :acknowledged_by, class_name: 'Weave::Core::MasterAdmin', optional: true
      belongs_to :resolved_by, class_name: 'Weave::Core::MasterAdmin', optional: true
      
      validates :alert_type, presence: true
      validates :severity, presence: true, inclusion: { in: %w[low medium high critical] }
      validates :title, presence: true
      validates :status, inclusion: { in: %w[active acknowledged resolved] }
      
      scope :active, -> { where(status: 'active') }
      scope :acknowledged, -> { where(status: 'acknowledged') }
      scope :resolved, -> { where(status: 'resolved') }
      scope :by_severity, ->(severity) { where(severity: severity) }
      scope :for_account, ->(account_id) { where(account_id: account_id) }
      scope :recent, -> { order(created_at: :desc) }
      scope :unresolved, -> { where(status: %w[active acknowledged]) }
      
      ALERT_TYPES = %w[
        payment_failed
        trial_expiring_soon
        trial_expired
        integration_down
        api_limit_exceeded
        webhook_failing
        high_error_rate
        storage_limit_exceeded
        bandwidth_limit_exceeded
        feature_limit_exceeded
        subscription_canceled
        refund_requested
        chargeback_received
      ].freeze
      
      SEVERITIES = %w[low medium high critical].freeze
      
      def metadata_parsed
        return {} if metadata.blank?
        JSON.parse(metadata)
      rescue JSON::ParserError
        {}
      end
      
      def metadata_parsed=(meta_hash)
        self.metadata = meta_hash.to_json
      end
      
      def severity_color
        case severity
        when 'low' then '#10B981'      # green-500
        when 'medium' then '#F59E0B'   # amber-500
        when 'high' then '#EF4444'     # red-500
        when 'critical' then '#DC2626' # red-600
        else '#6B7280'                 # gray-500
        end
      end
      
      def severity_badge_class
        case severity
        when 'low' then 'bg-green-100 text-green-800'
        when 'medium' then 'bg-amber-100 text-amber-800'
        when 'high' then 'bg-red-100 text-red-800'
        when 'critical' then 'bg-red-200 text-red-900 font-bold'
        else 'bg-gray-100 text-gray-800'
        end
      end
      
      def status_badge_class
        case status
        when 'active' then 'bg-red-100 text-red-800'
        when 'acknowledged' then 'bg-amber-100 text-amber-800'
        when 'resolved' then 'bg-green-100 text-green-800'
        else 'bg-gray-100 text-gray-800'
        end
      end
      
      def alert_type_display
        case alert_type
        when 'payment_failed' then 'Payment Failed'
        when 'trial_expiring_soon' then 'Trial Expiring Soon'
        when 'trial_expired' then 'Trial Expired'
        when 'integration_down' then 'Integration Down'
        when 'api_limit_exceeded' then 'API Limit Exceeded'
        when 'webhook_failing' then 'Webhook Failing'
        when 'high_error_rate' then 'High Error Rate'
        when 'storage_limit_exceeded' then 'Storage Limit Exceeded'
        when 'bandwidth_limit_exceeded' then 'Bandwidth Limit Exceeded'
        when 'feature_limit_exceeded' then 'Feature Limit Exceeded'
        when 'subscription_canceled' then 'Subscription Canceled'
        when 'refund_requested' then 'Refund Requested'
        when 'chargeback_received' then 'Chargeback Received'
        else alert_type.humanize
        end
      end
      
      def can_be_acknowledged?
        status == 'active'
      end
      
      def can_be_resolved?
        status.in?(%w[active acknowledged])
      end
      
      def acknowledge!(admin, reason = nil)
        return false unless can_be_acknowledged?
        
        update!(
          status: 'acknowledged',
          acknowledged_by: admin,
          acknowledged_at: Time.current
        )
        
        # Log the acknowledgment
        admin.log_action!(
          'alert_acknowledged',
          account: account,
          resource_type: 'system_alert',
          resource_id: id.to_s,
          action_details: { alert_type: alert_type, title: title },
          reason: reason
        )
        
        true
      end
      
      def resolve!(admin, reason = nil)
        return false unless can_be_resolved?
        
        update!(
          status: 'resolved',
          resolved_by: admin,
          resolved_at: Time.current
        )
        
        # Log the resolution
        admin.log_action!(
          'alert_resolved',
          account: account,
          resource_type: 'system_alert',
          resource_id: id.to_s,
          action_details: { alert_type: alert_type, title: title },
          reason: reason
        )
        
        true
      end
      
      def time_since_created
        distance = Time.current - created_at
        
        case distance
        when 0..59.seconds
          "#{distance.to_i}s ago"
        when 1.minute..59.minutes
          "#{(distance / 1.minute).to_i}m ago"
        when 1.hour..23.hours
          "#{(distance / 1.hour).to_i}h ago"
        else
          "#{(distance / 1.day).to_i}d ago"
        end
      end
      
      def self.create_alert!(alert_type, account: nil, severity: 'medium', title:, description: nil, metadata: {})
        # Don't create duplicate active alerts for the same issue
        existing = active.where(
          alert_type: alert_type,
          account: account,
          title: title
        ).first
        
        if existing
          # Update existing alert's metadata
          existing.metadata_parsed = existing.metadata_parsed.merge(metadata)
          existing.save!
          return existing
        end
        
        create!(
          alert_type: alert_type,
          account: account,
          severity: severity,
          title: title,
          description: description,
          metadata: metadata.to_json,
          status: 'active'
        )
      end
      
      def self.alert_stats
        {
          total_active: active.count,
          by_severity: group(:severity).count,
          by_type: group(:alert_type).count,
          recent_resolved: resolved.where('resolved_at >= ?', 24.hours.ago).count
        }
      end
      
      def self.critical_alerts
        active.where(severity: 'critical').recent
      end
      
      def self.cleanup_old_resolved!(days = 90)
        resolved.where('resolved_at < ?', days.days.ago).delete_all
      end
    end
  end
end