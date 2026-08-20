module AccountCaptainAutoResolve
  extend ActiveSupport::Concern

  VALID_CAPTAIN_AUTO_RESOLVE_MODES = %w[evaluated legacy disabled].freeze

  included do
    VALID_CAPTAIN_AUTO_RESOLVE_MODES.each do |mode|
      define_method("captain_auto_resolve_#{mode}?") do
        captain_auto_resolve_mode == mode
      end
    end
  end

  def captain_auto_resolve_mode
    mode = settings&.[]('captain_auto_resolve_mode')
    return mode if VALID_CAPTAIN_AUTO_RESOLVE_MODES.include?(mode)
    return 'disabled' if settings&.[]('captain_disable_auto_resolve') == true

    feature_enabled?('captain_tasks') ? 'evaluated' : 'legacy'
  end

  # Auto-sync interval for Captain documents, keyed by plan name. Reads the
  # CAPTAIN_DOCUMENT_AUTO_SYNC_INTERVALS installation config (a JSON map of
  # plan -> hours). Migrated here from the Enterprise::Account module so the
  # AI agent keeps its document sync behaviour without the enterprise overlay.
  class << self
    def captain_document_sync_intervals
      parse_captain_document_sync_intervals(
        InstallationConfig.find_by(name: 'CAPTAIN_DOCUMENT_AUTO_SYNC_INTERVALS')&.value
      )
    end

    private

    def parse_captain_document_sync_intervals(configured_intervals)
      return {} if configured_intervals.blank?

      parsed_intervals = configured_intervals.is_a?(String) ? JSON.parse(configured_intervals) : configured_intervals
      return {} unless parsed_intervals.is_a?(Hash)

      parsed_intervals.transform_keys(&:to_s).transform_keys(&:downcase)
    rescue JSON::ParserError
      {}
    end
  end

  def captain_document_sync_interval(sync_intervals = self.class.captain_document_sync_intervals)
    plan = custom_attributes['plan_name']
    return nil if plan.blank?

    interval_hours = sync_intervals[plan.downcase]
    return nil unless interval_hours.is_a?(Integer) && interval_hours.positive?

    interval_hours.hours
  end
end
