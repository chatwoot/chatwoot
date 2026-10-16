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
end
