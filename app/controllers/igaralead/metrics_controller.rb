module Igaralead
  class MetricsController < ApplicationController
    skip_before_action :verify_authenticity_token, raise: false
    skip_before_action :authenticate_user!, raise: false
    before_action :authenticate_api_key!

    def show
      account = Account.find_by(hub_client_slug: params[:client_slug])
      return render json: { error: 'Account not found' }, status: :not_found unless account

      render json: build_metrics(account)
    end

    private

    def authenticate_api_key!
      api_key = request.headers['X-Api-Key'] || params[:api_key]
      expected = ENV.fetch('HUB_METRICS_API_KEY', '')

      return if expected.present? && ActiveSupport::SecurityUtils.secure_compare(api_key.to_s, expected)

      render json: { error: 'Unauthorized' }, status: :unauthorized
    end

    def build_metrics(account)
      now = Time.current
      month_start = now.beginning_of_month

      {
        account_id: account.id,
        client_slug: account.hub_client_slug,
        collected_at: now.iso8601,
        users: user_metrics(account),
        conversations: conversation_metrics(account, month_start, now),
        contacts: contact_metrics(account),
        inboxes: inbox_metrics(account),
        agents: agent_metrics(account)
      }
    end

    def user_metrics(account)
      {
        total: account.users.count,
        active: account.users.where(availability: :online).count
      }
    end

    def conversation_metrics(account, since, until_time)
      conversations = account.conversations
      {
        total: conversations.count,
        open: conversations.where(status: :open).count,
        resolved: conversations.where(status: :resolved).count,
        pending: conversations.where(status: :pending).count,
        this_month: conversations.where(created_at: since..until_time).count
      }
    end

    def contact_metrics(account)
      {
        total: account.contacts.count
      }
    end

    def inbox_metrics(account)
      inboxes = account.inboxes
      {
        total: inboxes.count,
        by_type: inboxes.group(:channel_type).count
      }
    end

    def agent_metrics(account)
      {
        total: account.agents.count,
        administrators: account.administrators.count
      }
    end
  end
end
