module Weave
  module Core
    class MasterAdmin < ApplicationRecord
      self.table_name = 'weave_core_master_admins'
      
      has_many :admin_sessions, class_name: 'Weave::Core::MasterAdminSession', 
               foreign_key: 'master_admin_id', dependent: :destroy
      has_many :audit_logs, class_name: 'Weave::Core::AdminAuditLog',
               foreign_key: 'master_admin_id', dependent: :restrict_with_exception
      has_many :granted_benefits, class_name: 'Weave::Core::TenantBenefit',
               foreign_key: 'granted_by_id', dependent: :restrict_with_exception
      has_many :acknowledged_alerts, class_name: 'Weave::Core::SystemAlert',
               foreign_key: 'acknowledged_by_id', dependent: :nullify
      has_many :resolved_alerts, class_name: 'Weave::Core::SystemAlert',
               foreign_key: 'resolved_by_id', dependent: :nullify
      
      validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
      validates :name, presence: true
      validates :role, presence: true, inclusion: { in: %w[admin super_admin support] }
      
      scope :active, -> { where(active: true) }
      scope :by_role, ->(role) { where(role: role) }
      
      ROLES = %w[admin super_admin support].freeze
      
      def permissions_list
        return [] if permissions.blank?
        JSON.parse(permissions)
      rescue JSON::ParserError
        []
      end
      
      def permissions_list=(permission_names)
        self.permissions = permission_names.to_json
      end
      
      def has_permission?(permission_name)
        return true if super_admin? # Super admins have all permissions
        permissions_list.include?(permission_name.to_s)
      end
      
      def super_admin?
        role == 'super_admin'
      end
      
      def support?
        role == 'support'
      end
      
      def admin?
        role == 'admin'
      end
      
      def role_display
        case role
        when 'super_admin' then 'Super Admin'
        when 'admin' then 'Admin'
        when 'support' then 'Support'
        else role.humanize
        end
      end
      
      def can_manage_tenants?
        has_permission?('manage_tenants') || super_admin?
      end
      
      def can_suspend_accounts?
        has_permission?('suspend_accounts') || super_admin?
      end
      
      def can_grant_benefits?
        has_permission?('grant_benefits') || super_admin?
      end
      
      def can_force_upgrades?
        has_permission?('force_upgrades') || super_admin?
      end
      
      def can_view_billing?
        has_permission?('view_billing') || super_admin?
      end
      
      def can_manage_alerts?
        has_permission?('manage_alerts') || admin? || super_admin?
      end
      
      def can_access_console?
        active? && (admin? || super_admin? || support?)
      end
      
      # Privacy safeguard - master admins can NEVER access conversation data
      def can_read_conversations?
        false # Explicit privacy protection
      end
      
      def can_read_messages?
        false # Explicit privacy protection
      end
      
      def authenticate_password(password)
        # Simple password check - in production you'd use bcrypt
        encrypted_password == Digest::SHA256.hexdigest(password + email)
      end
      
      def set_password!(password)
        self.encrypted_password = Digest::SHA256.hexdigest(password + email)
        save!
      end
      
      def create_session!(ip_address = nil, user_agent = nil)
        # End existing sessions
        admin_sessions.where('expires_at > ?', Time.current).update_all(expires_at: Time.current)
        
        # Create new session
        session_token = SecureRandom.hex(32)
        
        admin_sessions.create!(
          session_token: session_token,
          ip_address: ip_address,
          user_agent: user_agent,
          expires_at: 8.hours.from_now
        )
        
        update!(
          session_token: session_token,
          last_login_at: Time.current,
          last_login_ip: ip_address
        )
        
        session_token
      end
      
      def valid_session?(token)
        return false unless token
        
        session = admin_sessions.find_by(session_token: token)
        session&.expires_at&.> Time.current
      end
      
      def end_session!(token = nil)
        if token
          admin_sessions.where(session_token: token).update_all(expires_at: Time.current)
        else
          admin_sessions.update_all(expires_at: Time.current)
        end
        
        update!(session_token: nil)
      end
      
      def log_action!(action_type, account: nil, resource_type: nil, resource_id: nil, action_details: {}, reason: nil, ip_address: nil)
        audit_logs.create!(
          account: account,
          action_type: action_type,
          resource_type: resource_type,
          resource_id: resource_id,
          action_details: action_details.to_json,
          reason: reason,
          ip_address: ip_address
        )
      end
      
      def self.default_permissions
        {
          'admin' => %w[
            manage_tenants
            suspend_accounts
            grant_benefits
            view_billing
            manage_alerts
          ],
          'super_admin' => %w[
            manage_tenants
            suspend_accounts
            grant_benefits
            force_upgrades
            view_billing
            manage_alerts
            manage_admins
          ],
          'support' => %w[
            view_tenants
            manage_alerts
          ]
        }
      end
      
      def self.create_with_defaults!(attributes)
        admin = new(attributes)
        admin.permissions_list = default_permissions[admin.role] || []
        admin.save!
        admin
      end
      
      def self.authenticate(email, password)
        admin = active.find_by(email: email.downcase.strip)
        return nil unless admin&.authenticate_password(password)
        admin
      end
    end
  end
end