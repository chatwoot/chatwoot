module InboxCsat
  extend ActiveSupport::Concern

  DEFAULT_RESPONSE_WINDOW_DAYS = 14

  included do
    validate :ensure_valid_csat_response_window
  end

  def csat_response_window_days
    csat_config.fetch('response_window_days', DEFAULT_RESPONSE_WINDOW_DAYS)
  end

  private

  def ensure_valid_csat_response_window
    return unless csat_config.key?('response_window_days')

    days = csat_config['response_window_days']
    return if days.is_a?(Integer) && days.positive?

    errors.add(:csat_config, I18n.t('errors.csat_survey.invalid_response_window'))
  end
end
