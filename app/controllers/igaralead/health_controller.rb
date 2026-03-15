# frozen_string_literal: true

module Igaralead
  class HealthController < ApplicationController
    skip_before_action :verify_authenticity_token, raise: false
    skip_before_action :authenticate_user!, raise: false

    def show
      checks = {
        api: 'ok',
        database: check_database,
        redis: check_redis,
        sidekiq: check_sidekiq
      }

      overall = checks.values.all? { |v| v.in?(%w[ok unavailable]) }

      render json: {
        status: overall ? 'ok' : 'degraded',
        product: 'nexus',
        version: Chatwoot.config[:version],
        checks: checks
      }
    end

    private

    def check_database
      ActiveRecord::Base.connection.execute('SELECT 1')
      'ok'
    rescue StandardError
      'error'
    end

    def check_redis
      Redis::Alfred.redis.ping
      'ok'
    rescue StandardError
      'error'
    end

    def check_sidekiq
      Sidekiq::ProcessSet.new.size.positive? ? 'ok' : 'unavailable'
    rescue StandardError
      'unavailable'
    end
  end
end
