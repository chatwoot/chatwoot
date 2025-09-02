module Weave
  module Core
    module Admin
      class RateLimitsController < ApplicationController
        before_action :ensure_admin
        before_action :find_account, only: [:show, :create_override, :expire_override]

        def index
          @accounts = Account.joins(:account_plan)
                            .includes(:rate_limit_overrides)
                            .order(:name)
                            .page(params[:page])
                            .per(20)

          # Get usage statistics for all accounts
          @usage_stats = @accounts.map do |account|
            usage = {}
            RateLimits::PLAN_LIMITS['basic'].keys.each do |category|
              usage[category] = RateLimits.usage_percentage_for_account(account.id, category)
            end
            [account.id, usage]
          end.to_h
        end

        def show
          @current_limits = RateLimits.current_limits_for_account(@account.id)
          @active_overrides = @account.rate_limit_overrides.active.order(:created_at)
          @recent_overrides = @account.rate_limit_overrides.expired
                                     .order(created_at: :desc)
                                     .limit(10)

          # Get real-time usage for each category
          @usage_stats = {}
          @current_limits.each do |category, info|
            @usage_stats[category] = {
              current_usage: RateLimits.current_usage_for_account(@account.id, category),
              percentage: RateLimits.usage_percentage_for_account(@account.id, category),
              limit: info[:current_limit]
            }
          end
        end

        def create_override
          @override = RateLimits.create_override!(
            @account.id,
            override_params[:category],
            override_params[:override_limit].to_i,
            parse_expires_at,
            override_params[:reason],
            current_user.id,
            notes: override_params[:notes]
          )

          if @override.persisted?
            redirect_to admin_rate_limit_path(@account), notice: 'Rate limit override created successfully.'
          else
            redirect_to admin_rate_limit_path(@account), alert: @override.errors.full_messages.join(', ')
          end
        rescue ActiveRecord::RecordInvalid => e
          redirect_to admin_rate_limit_path(@account), alert: e.record.errors.full_messages.join(', ')
        end

        def expire_override
          @override = RateLimits.expire_override!(params[:override_id])
          redirect_to admin_rate_limit_path(@account), notice: 'Rate limit override expired successfully.'
        rescue ActiveRecord::RecordNotFound
          redirect_to admin_rate_limit_path(@account), alert: 'Override not found.'
        end

        def analytics
          @time_range = params[:time_range] || '24h'
          @analytics = RateLimitAnalytics.new(@time_range).generate
        end

        private

        def find_account
          @account = Account.find(params[:account_id])
        end

        def ensure_admin
          redirect_to root_path unless current_user&.super_admin?
        end

        def override_params
          params.require(:override).permit(:category, :override_limit, :expires_in, :reason, :notes)
        end

        def parse_expires_at
          expires_in = override_params[:expires_in].to_i
          case expires_in
          when 1 then 1.hour.from_now
          when 24 then 1.day.from_now
          when 168 then 1.week.from_now
          when 720 then 1.month.from_now
          else 1.hour.from_now
          end
        end
      end
    end
  end
end