module Weave
  module Core
    module Api
      module MasterAdmin
        class TenantsController < MasterAdminController
          before_action :require_tenant_management_permission, except: [:index, :show]
          
          def index
            # Get all accounts with aggregated data - NO conversation/message access
            accounts = Account.includes(
              :users,
              :weave_core_account_subscription,
              inboxes: [:channel]
            ).page(params[:page]).per(params[:per_page] || 25)
            
            # Apply filters
            accounts = filter_accounts(accounts)
            
            tenant_data = accounts.map do |account|
              build_tenant_summary(account)
            end
            
            render json: {
              success: true,
              tenants: tenant_data,
              pagination: {
                current_page: accounts.current_page,
                total_pages: accounts.total_pages,
                total_count: accounts.total_count,
                per_page: accounts.limit_value
              },
              summary: build_system_summary
            }
          end
          
          def show
            account = Account.find(params[:id])
            
            render json: {
              success: true,
              tenant: build_detailed_tenant_info(account)
            }
          end
          
          def suspend
            account = Account.find(params[:id])
            reason = params[:reason] || 'Administrative action'
            
            # Suspend the account's subscription
            subscription = account.weave_core_account_subscription
            if subscription
              service = Weave::Core::SubscriptionService.new(account)
              service.suspend_access!(reason)
            end
            
            # Log the action
            current_admin.log_action!(
              'tenant_suspended',
              account: account,
              reason: reason,
              ip_address: request.remote_ip
            )
            
            render json: {
              success: true,
              message: "Tenant #{account.name} has been suspended",
              tenant: build_tenant_summary(account.reload)
            }
          end
          
          def reactivate
            account = Account.find(params[:id])
            reason = params[:reason] || 'Administrative reactivation'
            
            # Reactivate the subscription
            subscription = account.weave_core_account_subscription
            if subscription
              service = Weave::Core::SubscriptionService.new(account)
              service.reactivate_subscription! if service.can_reactivate?
            end
            
            # Log the action
            current_admin.log_action!(
              'tenant_reactivated',
              account: account,
              reason: reason,
              ip_address: request.remote_ip
            )
            
            render json: {
              success: true,
              message: "Tenant #{account.name} has been reactivated",
              tenant: build_tenant_summary(account.reload)
            }
          end
          
          def force_upgrade
            account = Account.find(params[:id])
            target_plan = params.require(:plan_type)
            reason = params[:reason] || 'Administrative upgrade'
            
            service = Weave::Core::SubscriptionService.new(account)
            old_plan = service.current_subscription&.subscription_plan&.plan_type
            
            begin
              service.change_plan!(target_plan)
              
              # Log the action
              current_admin.log_action!(
                'subscription_upgraded',
                account: account,
                action_details: {
                  old_plan: old_plan,
                  new_plan: target_plan
                },
                reason: reason,
                ip_address: request.remote_ip
              )
              
              render json: {
                success: true,
                message: "Tenant #{account.name} upgraded to #{target_plan}",
                tenant: build_tenant_summary(account.reload)
              }
              
            rescue => e
              render json: {
                success: false,
                error: "Failed to upgrade tenant: #{e.message}"
              }, status: :unprocessable_entity
            end
          end
          
          def grant_benefit
            account = Account.find(params[:id])
            benefit_params = params.require(:benefit)
            
            benefit_type = benefit_params.require(:type)
            benefit_value = benefit_params[:value]
            description = benefit_params[:description]
            expires_at = benefit_params[:expires_at]&.to_datetime
            grant_reason = benefit_params[:reason] || 'Administrative benefit'
            
            begin
              benefit = Weave::Core::TenantBenefit.grant_benefit!(
                account,
                current_admin,
                benefit_type,
                benefit_value,
                description: description,
                expires_at: expires_at,
                grant_reason: grant_reason
              )
              
              render json: {
                success: true,
                message: "Benefit granted to #{account.name}",
                benefit: serialize_benefit(benefit),
                tenant: build_tenant_summary(account.reload)
              }
              
            rescue => e
              render json: {
                success: false,
                error: "Failed to grant benefit: #{e.message}"
              }, status: :unprocessable_entity
            end
          end
          
          def revoke_benefit
            account = Account.find(params[:id])
            benefit = account.weave_core_tenant_benefits.find(params[:benefit_id])
            reason = params[:reason] || 'Administrative revocation'
            
            benefit.revoke!(current_admin, reason)
            
            render json: {
              success: true,
              message: "Benefit revoked from #{account.name}",
              tenant: build_tenant_summary(account.reload)
            }
          end
          
          private
          
          def require_tenant_management_permission
            unless current_admin.can_manage_tenants?
              render json: { error: 'Insufficient permissions' }, status: :forbidden
            end
          end
          
          def filter_accounts(accounts)
            # Filter by subscription status
            if params[:status].present?
              case params[:status]
              when 'trial'
                accounts = accounts.joins(:weave_core_account_subscription)
                                 .where(weave_core_account_subscriptions: { status: 'trial' })
              when 'active'
                accounts = accounts.joins(:weave_core_account_subscription)
                                 .where(weave_core_account_subscriptions: { status: 'active' })
              when 'suspended'
                accounts = accounts.joins(:weave_core_account_subscription)
                                 .where(weave_core_account_subscriptions: { status: 'suspended' })
              end
            end
            
            # Filter by plan
            if params[:plan].present?
              accounts = accounts.joins(weave_core_account_subscription: :subscription_plan)
                               .where(weave_core_subscription_plans: { plan_type: params[:plan] })
            end
            
            # Search by name
            if params[:search].present?
              accounts = accounts.where('accounts.name ILIKE ?', "%#{params[:search]}%")
            end
            
            accounts
          end
          
          def build_tenant_summary(account)
            subscription = account.weave_core_account_subscription
            
            # Count channels by type (NO access to conversation content)
            channel_counts = account.inboxes.joins(:channel).group('channels.channel_type').count
            
            # Get recent alerts for this account
            recent_alerts = Weave::Core::SystemAlert.for_account(account.id)
                                                   .unresolved
                                                   .limit(5)
            
            # Get active benefits
            active_benefits = account.weave_core_tenant_benefits
                                   .active
                                   .unexpired
                                   .limit(5)
            
            {
              id: account.id,
              name: account.name,
              domain: account.domain,
              status: subscription&.status || 'no_subscription',
              subscription: subscription ? {
                id: subscription.id,
                plan_type: subscription.subscription_plan&.plan_type,
                plan_display_name: subscription.subscription_plan&.display_name,
                billing_cycle: subscription.billing_cycle,
                trial: subscription.trial?,
                trial_ends_at: subscription.trial_ends_at&.iso8601,
                trial_days_remaining: subscription.trial_days_remaining,
                current_period_end: subscription.current_period_end&.iso8601,
                status_display: subscription.status_display
              } : nil,
              users_count: account.users.count,
              inboxes_count: account.inboxes.count,
              channels: {
                total: channel_counts.values.sum,
                by_type: channel_counts
              },
              alerts: {
                active_count: recent_alerts.count,
                recent: recent_alerts.map { |alert| serialize_alert_summary(alert) }
              },
              benefits: {
                active_count: active_benefits.count,
                recent: active_benefits.map { |benefit| serialize_benefit_summary(benefit) }
              },
              created_at: account.created_at.iso8601,
              updated_at: account.updated_at.iso8601
            }
          end
          
          def build_detailed_tenant_info(account)
            base_info = build_tenant_summary(account)
            
            # Add more detailed information
            subscription = account.weave_core_account_subscription
            
            base_info.merge({
              subscription_history: subscription ? {
                payment_records_count: subscription.payment_records.count,
                last_payment: subscription.last_successful_payment&.processed_at&.iso8601,
                failed_payments_count: subscription.failed_payments_count,
                provider: subscription.payment_provider
              } : nil,
              
              feature_toggles: account.weave_core_feature_toggles.pluck(:feature_key, :enabled).to_h,
              
              system_metrics: {
                # Add non-private metrics here
                storage_used: calculate_storage_usage(account),
                api_usage_last_30_days: calculate_api_usage(account),
                webhook_events_count: account.webhook_events&.count || 0
              }
            })
          end
          
          def build_system_summary
            {
              total_tenants: Account.count,
              active_subscriptions: Weave::Core::AccountSubscription.active_subscriptions.count,
              trial_subscriptions: Weave::Core::AccountSubscription.trial.count,
              suspended_accounts: Weave::Core::AccountSubscription.where(status: 'suspended').count,
              active_alerts: Weave::Core::SystemAlert.active.count,
              critical_alerts: Weave::Core::SystemAlert.critical_alerts.count
            }
          end
          
          def serialize_alert_summary(alert)
            {
              id: alert.id,
              type: alert.alert_type,
              severity: alert.severity,
              title: alert.title,
              status: alert.status,
              created_at: alert.created_at.iso8601
            }
          end
          
          def serialize_benefit_summary(benefit)
            {
              id: benefit.id,
              type: benefit.benefit_type,
              description: benefit.benefit_description,
              expires_at: benefit.expires_at&.iso8601,
              active: benefit.active
            }
          end
          
          def serialize_benefit(benefit)
            {
              id: benefit.id,
              type: benefit.benefit_type,
              type_display: benefit.benefit_type_display,
              value: benefit.benefit_value,
              description: benefit.benefit_description,
              expires_at: benefit.expires_at&.iso8601,
              active: benefit.active,
              granted_by: benefit.granted_by.name,
              granted_at: benefit.created_at.iso8601,
              grant_reason: benefit.grant_reason
            }
          end
          
          # Safe metric calculations that don't access private data
          def calculate_storage_usage(account)
            # Calculate storage without accessing conversation content
            # This would typically query file attachments, not message content
            0 # Placeholder - implement based on your file storage system
          end
          
          def calculate_api_usage(account)
            # Calculate API usage from logs, not from conversation data
            0 # Placeholder - implement based on your API logging system
          end
        end
      end
    end
  end
end