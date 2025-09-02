# Master Admin Privacy Protection Initializer
# This ensures that privacy safeguards are loaded and active

require 'master_admin_privacy_guard'

Rails.application.configure do
  # Add the privacy middleware to the middleware stack
  config.middleware.insert_before Rack::Runtime, MasterAdminPrivacyMiddleware
  
  # Hook into Active Record to prevent dangerous queries from master admin contexts
  ActiveSupport.on_load(:active_record) do
    # Add privacy validation to query methods
    [ActiveRecord::Relation, ActiveRecord::Base].each do |klass|
      klass.class_eval do
        def self.privacy_guard_enabled?
          Thread.current[:master_admin_context] == true
        end
        
        def self.with_master_admin_context(&block)
          previous_context = Thread.current[:master_admin_context]
          Thread.current[:master_admin_context] = true
          yield
        ensure
          Thread.current[:master_admin_context] = previous_context
        end
        
        def self.without_master_admin_context(&block)
          previous_context = Thread.current[:master_admin_context]
          Thread.current[:master_admin_context] = false
          yield
        ensure
          Thread.current[:master_admin_context] = previous_context
        end
      end
    end
    
    # Override dangerous methods in master admin context
    ActiveRecord::Relation.class_eval do
      alias_method :original_to_sql, :to_sql
      
      def to_sql
        if self.class.privacy_guard_enabled?
          sql = original_to_sql
          begin
            MasterAdminPrivacyGuard.guard_query!(sql)
          rescue MasterAdminPrivacyGuard::PrivacyViolationError => e
            Rails.logger.error "Privacy violation blocked in SQL query: #{e.message}"
            Rails.logger.error "Attempted query: #{sql}"
            raise e
          end
        end
        original_to_sql
      end
    end
  end
end

# Configure logging for master admin actions
Rails.logger.info "Master Admin Privacy Guard initialized" if Rails.logger

# Set up monitoring for privacy violations
if defined?(Sentry)
  Sentry.configure_scope do |scope|
    scope.set_tag(:component, 'master_admin_privacy')
  end
end