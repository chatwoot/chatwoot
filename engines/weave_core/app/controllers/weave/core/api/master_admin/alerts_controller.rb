module Weave
  module Core
    module Api
      module MasterAdmin
        class AlertsController < MasterAdminController
          before_action :require_alert_management_permission
          
          def index
            alerts = Weave::Core::SystemAlert.includes(:account, :acknowledged_by, :resolved_by)
                                            .order(created_at: :desc)
            
            # Apply filters
            alerts = filter_alerts(alerts)
            
            # Paginate
            alerts = alerts.page(params[:page]).per(params[:per_page] || 25)
            
            render json: {
              success: true,
              alerts: alerts.map { |alert| serialize_alert(alert) },
              pagination: {
                current_page: alerts.current_page,
                total_pages: alerts.total_pages,
                total_count: alerts.total_count,
                per_page: alerts.limit_value
              },
              stats: Weave::Core::SystemAlert.alert_stats
            }
          end
          
          def show
            alert = Weave::Core::SystemAlert.find(params[:id])
            
            render json: {
              success: true,
              alert: serialize_alert_detailed(alert)
            }
          end
          
          def acknowledge
            alert = Weave::Core::SystemAlert.find(params[:id])
            reason = params[:reason]
            
            if alert.acknowledge!(current_admin, reason)
              render json: {
                success: true,
                message: 'Alert acknowledged',
                alert: serialize_alert(alert.reload)
              }
            else
              render json: {
                success: false,
                error: 'Failed to acknowledge alert'
              }, status: :unprocessable_entity
            end
          end
          
          def resolve
            alert = Weave::Core::SystemAlert.find(params[:id])
            reason = params[:reason]
            
            if alert.resolve!(current_admin, reason)
              render json: {
                success: true,
                message: 'Alert resolved',
                alert: serialize_alert(alert.reload)
              }
            else
              render json: {
                success: false,
                error: 'Failed to resolve alert'
              }, status: :unprocessable_entity
            end
          end
          
          def create
            # Manual alert creation
            alert_params = params.require(:alert)
            
            account = nil
            if alert_params[:account_id].present?
              account = Account.find(alert_params[:account_id])
            end
            
            alert = Weave::Core::SystemAlert.create_alert!(
              alert_params.require(:alert_type),
              account: account,
              severity: alert_params[:severity] || 'medium',
              title: alert_params.require(:title),
              description: alert_params[:description],
              metadata: alert_params[:metadata] || {}
            )
            
            # Log the manual alert creation
            current_admin.log_action!(
              'alert_created',
              account: account,
              resource_type: 'system_alert',
              resource_id: alert.id.to_s,
              action_details: {
                alert_type: alert.alert_type,
                title: alert.title,
                severity: alert.severity
              },
              reason: 'Manual alert creation',
              ip_address: request.remote_ip
            )
            
            render json: {
              success: true,
              message: 'Alert created',
              alert: serialize_alert(alert)
            }
          end
          
          def batch_acknowledge
            alert_ids = params.require(:alert_ids)
            reason = params[:reason] || 'Batch acknowledgment'
            
            alerts = Weave::Core::SystemAlert.where(id: alert_ids)
            acknowledged_count = 0
            
            alerts.each do |alert|
              if alert.acknowledge!(current_admin, reason)
                acknowledged_count += 1
              end
            end
            
            render json: {
              success: true,
              message: "#{acknowledged_count} alerts acknowledged",
              acknowledged_count: acknowledged_count
            }
          end
          
          def batch_resolve
            alert_ids = params.require(:alert_ids)
            reason = params[:reason] || 'Batch resolution'
            
            alerts = Weave::Core::SystemAlert.where(id: alert_ids)
            resolved_count = 0
            
            alerts.each do |alert|
              if alert.resolve!(current_admin, reason)
                resolved_count += 1
              end
            end
            
            render json: {
              success: true,
              message: "#{resolved_count} alerts resolved",
              resolved_count: resolved_count
            }
          end
          
          def stats
            render json: {
              success: true,
              stats: {
                overview: Weave::Core::SystemAlert.alert_stats,
                critical: Weave::Core::SystemAlert.critical_alerts.count,
                recent_activity: recent_alert_activity
              }
            }
          end
          
          private
          
          def require_alert_management_permission
            unless current_admin.can_manage_alerts?
              render json: { error: 'Insufficient permissions for alert management' }, status: :forbidden
            end
          end
          
          def filter_alerts(alerts)
            # Filter by status
            if params[:status].present?
              alerts = alerts.where(status: params[:status])
            end
            
            # Filter by severity  
            if params[:severity].present?
              alerts = alerts.where(severity: params[:severity])
            end
            
            # Filter by alert type
            if params[:alert_type].present?
              alerts = alerts.where(alert_type: params[:alert_type])
            end
            
            # Filter by account
            if params[:account_id].present?
              alerts = alerts.where(account_id: params[:account_id])
            end
            
            # Filter by date range
            if params[:start_date].present?
              alerts = alerts.where('created_at >= ?', Date.parse(params[:start_date]))
            end
            
            if params[:end_date].present?
              alerts = alerts.where('created_at <= ?', Date.parse(params[:end_date]).end_of_day)
            end
            
            alerts
          end
          
          def serialize_alert(alert)
            {
              id: alert.id,
              alert_type: alert.alert_type,
              alert_type_display: alert.alert_type_display,
              severity: alert.severity,
              title: alert.title,
              description: alert.description,
              status: alert.status,
              account: alert.account ? {
                id: alert.account.id,
                name: alert.account.name
              } : nil,
              acknowledged_by: alert.acknowledged_by ? {
                id: alert.acknowledged_by.id,
                name: alert.acknowledged_by.name
              } : nil,
              acknowledged_at: alert.acknowledged_at&.iso8601,
              resolved_by: alert.resolved_by ? {
                id: alert.resolved_by.id,
                name: alert.resolved_by.name
              } : nil,
              resolved_at: alert.resolved_at&.iso8601,
              created_at: alert.created_at.iso8601,
              time_since_created: alert.time_since_created
            }
          end
          
          def serialize_alert_detailed(alert)
            serialize_alert(alert).merge({
              metadata: alert.metadata_parsed,
              can_acknowledge: alert.can_be_acknowledged?,
              can_resolve: alert.can_be_resolved?
            })
          end
          
          def recent_alert_activity
            # Get alert activity for the last 7 days
            Weave::Core::SystemAlert
              .where('created_at >= ?', 7.days.ago)
              .group("DATE(created_at)")
              .group(:status)
              .count
              .transform_keys { |key| { date: key[0], status: key[1] } }
          end
        end
      end
    end
  end
end