# frozen_string_literal: true

# Inherits from ActionController::Base to skip auth, like HealthController.
class MetricsController < ActionController::Base # rubocop:disable Rails/ApplicationController
  def show
    unless ChatwootPrometheus.enabled?
      head :not_found
      return
    end

    render plain: ChatwootPrometheus.text, content_type: 'text/plain; version=0.0.4; charset=utf-8'
  end
end
