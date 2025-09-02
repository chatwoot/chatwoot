class MasterAdminPrivacyGuard
  # This class provides explicit privacy protection for master admin operations
  # It ensures that master admins can NEVER access tenant private data
  
  FORBIDDEN_MODELS = %w[
    Conversation
    Message
    Contact
    ContactInbox
    Event
    Note
    ConversationParticipant
  ].freeze
  
  FORBIDDEN_ATTRIBUTES = %w[
    content
    private_note
    email
    phone_number
    additional_attributes
    custom_attributes
    metadata
  ].freeze
  
  class PrivacyViolationError < StandardError; end
  
  class << self
    def guard_query!(query_string)
      # Prevent queries that could access private data
      query_lower = query_string.to_s.downcase
      
      FORBIDDEN_MODELS.each do |model|
        table_name = model.tableize
        if query_lower.include?(table_name) || query_lower.include?(model.underscore.pluralize)
          raise PrivacyViolationError, "Query attempted to access forbidden model: #{model}"
        end
      end
      
      FORBIDDEN_ATTRIBUTES.each do |attr|
        if query_lower.include?(attr)
          raise PrivacyViolationError, "Query attempted to access forbidden attribute: #{attr}"
        end
      end
    end
    
    def safe_account_includes
      # Returns a safe list of associations that can be included in Account queries
      [
        :users,
        :inboxes,
        :weave_core_account_plans,
        :weave_core_feature_toggles,
        :weave_core_tenant_benefits,
        :subscriptions,
        inboxes: [:channel]
      ]
    end
    
    def sanitize_account_data(account_data)
      # Remove any potentially sensitive data from account objects
      if account_data.is_a?(Hash)
        sanitize_hash(account_data)
      elsif account_data.is_a?(Array)
        account_data.map { |item| sanitize_account_data(item) }
      elsif account_data.respond_to?(:attributes)
        sanitize_hash(account_data.attributes)
      else
        account_data
      end
    end
    
    def verify_master_admin_permissions!(admin, action)
      raise PrivacyViolationError, "Invalid admin" unless admin.is_a?(Weave::Core::MasterAdmin)
      raise PrivacyViolationError, "Admin not active" unless admin.active?
      
      case action.to_s
      when 'read_conversations', 'read_messages', 'read_contacts'
        raise PrivacyViolationError, "Master admins cannot access private tenant data"
      when 'manage_tenants'
        raise PrivacyViolationError, "Insufficient permissions" unless admin.can_manage_tenants?
      when 'suspend_accounts'
        raise PrivacyViolationError, "Insufficient permissions" unless admin.can_suspend_accounts?
      when 'force_upgrades'
        raise PrivacyViolationError, "Insufficient permissions" unless admin.can_force_upgrades?
      when 'grant_benefits'
        raise PrivacyViolationError, "Insufficient permissions" unless admin.can_grant_benefits?
      when 'view_billing'
        raise PrivacyViolationError, "Insufficient permissions" unless admin.can_view_billing?
      when 'manage_alerts'
        raise PrivacyViolationError, "Insufficient permissions" unless admin.can_manage_alerts?
      end
    end
    
    def audit_master_admin_action!(admin, action, account: nil, details: {})
      # Log all master admin actions for audit purposes
      admin.log_action!(
        action,
        account: account,
        action_details: details,
        ip_address: details[:ip_address],
        reason: details[:reason]
      )
      
      # Also log to Rails logger for immediate visibility
      Rails.logger.info({
        event: 'master_admin_action',
        admin_id: admin.id,
        admin_email: admin.email,
        action: action,
        account_id: account&.id,
        account_name: account&.name,
        details: details.except(:ip_address, :reason),
        timestamp: Time.current.iso8601
      }.to_json)
    end
    
    def create_privacy_alert!(violation_type, admin, details = {})
      # Create a critical alert when privacy boundaries are attempted to be crossed
      Weave::Core::SystemAlert.create_alert!(
        'privacy_violation_attempt',
        account: nil, # System-level alert
        severity: 'critical',
        title: "Privacy violation attempt detected",
        description: "Master admin #{admin.email} attempted to #{violation_type}",
        metadata: {
          admin_id: admin.id,
          admin_email: admin.email,
          violation_type: violation_type,
          details: details,
          timestamp: Time.current.iso8601
        }
      )
    rescue StandardError => e
      Rails.logger.error "Failed to create privacy alert: #{e.message}"
      # Continue execution - we don't want to break the system if alert creation fails
    end
    
    def validate_api_endpoint!(endpoint_path, admin)
      # Validate that the API endpoint is safe for master admin access
      forbidden_patterns = [
        %r{/api/v1/accounts/\d+/conversations},
        %r{/api/v1/accounts/\d+/messages},
        %r{/api/v1/accounts/\d+/contacts},
        %r{/api/v1/accounts/\d+/inbox_conversations},
        %r{/api/v1/accounts/\d+/conversation_participants}
      ]
      
      forbidden_patterns.each do |pattern|
        if endpoint_path.match?(pattern)
          create_privacy_alert!("access_forbidden_endpoint", admin, { endpoint: endpoint_path })
          raise PrivacyViolationError, "Access to endpoint #{endpoint_path} is forbidden for master admins"
        end
      end
    end
    
    def allowed_account_attributes
      # List of account attributes that are safe to expose to master admins
      %w[
        id
        name
        domain
        status
        locale
        support_email
        feature_flags
        auto_resolve_duration
        limits
        settings
        created_at
        updated_at
      ]
    end
    
    def allowed_user_attributes
      # List of user attributes that are safe to expose (no PII)
      %w[
        id
        role
        availability
        custom_role_id
        created_at
        updated_at
      ]
    end
    
    def filter_safe_attributes(object, allowed_attributes)
      if object.respond_to?(:attributes)
        object.attributes.slice(*allowed_attributes)
      elsif object.is_a?(Hash)
        object.slice(*allowed_attributes)
      else
        {}
      end
    end
    
    private
    
    def sanitize_hash(hash)
      sanitized = {}
      
      hash.each do |key, value|
        key_str = key.to_s.downcase
        
        # Skip forbidden attributes
        next if FORBIDDEN_ATTRIBUTES.any? { |attr| key_str.include?(attr) }
        
        # Skip attributes that look like they contain PII
        next if key_str.match?(/email|phone|address|ssn|tax|personal|private|secret/)
        
        # Recursively sanitize nested data
        sanitized[key] = if value.is_a?(Hash)
                          sanitize_hash(value)
                        elsif value.is_a?(Array)
                          value.map { |item| sanitize_account_data(item) }
                        else
                          value
                        end
      end
      
      sanitized
    end
  end
end

# Add middleware to intercept and validate master admin requests
class MasterAdminPrivacyMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)
    
    # Check if this is a master admin API request
    if request.path.start_with?('/wsc/api/master_admin')
      admin_token = extract_admin_token(request)
      
      if admin_token
        admin = find_admin_by_token(admin_token)
        
        if admin
          begin
            MasterAdminPrivacyGuard.validate_api_endpoint!(request.path, admin)
          rescue MasterAdminPrivacyGuard::PrivacyViolationError => e
            return [403, { 'Content-Type' => 'application/json' }, [{ error: e.message }.to_json]]
          end
        end
      end
    end
    
    @app.call(env)
  end

  private

  def extract_admin_token(request)
    auth_header = request.get_header('HTTP_AUTHORIZATION')
    if auth_header&.start_with?('Bearer ')
      return auth_header.sub('Bearer ', '')
    end
    
    request.get_header('HTTP_X_ADMIN_TOKEN')
  end

  def find_admin_by_token(token)
    session = Weave::Core::MasterAdminSession.active.find_by(session_token: token)
    session&.master_admin
  end
end