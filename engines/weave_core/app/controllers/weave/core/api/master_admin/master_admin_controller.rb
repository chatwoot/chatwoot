module Weave
  module Core
    module Api
      module MasterAdmin
        class MasterAdminController < ApplicationController
          # Skip Chatwoot's standard authentication
          skip_before_action :authenticate_user!, :current_account
          
          # Use master admin authentication instead  
          before_action :authenticate_master_admin!
          before_action :ensure_master_admin_access!
          
          protected
          
          def authenticate_master_admin!
            token = extract_admin_token
            
            unless token
              render json: { error: 'Authentication required' }, status: :unauthorized
              return
            end
            
            admin = find_admin_by_token(token)
            
            unless admin
              render json: { error: 'Invalid or expired session' }, status: :unauthorized
              return
            end
            
            @current_admin = admin
            
            # Extend session if it's about to expire
            session = admin.admin_sessions.find_by(session_token: token)
            if session&.time_remaining && session.time_remaining < 1 # Less than 1 hour
              session.extend_session!
            end
          end
          
          def ensure_master_admin_access!
            unless current_admin&.can_access_console?
              render json: { error: 'Access denied' }, status: :forbidden
            end
          end
          
          def current_admin
            @current_admin
          end
          
          private
          
          def extract_admin_token
            # Try Authorization header first
            auth_header = request.headers['Authorization']
            if auth_header&.start_with?('Bearer ')
              return auth_header.sub('Bearer ', '')
            end
            
            # Try X-Admin-Token header
            request.headers['X-Admin-Token']
          end
          
          def find_admin_by_token(token)
            # Find admin by active session token
            session = Weave::Core::MasterAdminSession.active.find_by(session_token: token)
            return nil unless session
            
            admin = session.master_admin
            return nil unless admin&.active?
            
            admin
          end
          
          # Privacy safeguards - these methods explicitly prevent access to private data
          def prevent_conversation_access!
            # This is a safety check to ensure no conversation data is ever accessed
            # Should be called by any method that might accidentally query conversation data
            raise SecurityError, "Master admins cannot access conversation data"
          end
          
          def prevent_message_access!
            # This is a safety check to ensure no message data is ever accessed  
            raise SecurityError, "Master admins cannot access message data"
          end
          
          def safe_account_query
            # Returns an Account relation with privacy-safe includes only
            Account.includes(
              :users,
              :weave_core_account_subscription,
              :weave_core_feature_toggles,
              :weave_core_tenant_benefits,
              inboxes: [:channel]
              # NOTE: Explicitly NOT including :conversations, :messages, or any content
            )
          end
        end
      end
    end
  end
end