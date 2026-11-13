# How a Twilio inbox rings its agents, kept in provider_config. Incoming calls ring every eligible
# agent at once, or one more agent every step. A plain module (no ActiveSupport::Concern) so it can
# be included into a prepended Enterprise module, which registers the validation.
module Concerns::CallRoutingSettings
  RING_STRATEGIES = %w[simultaneous sequential].freeze
  DEFAULT_RING_STEP_SECONDS = 20
  RING_STEP_SECONDS = (10..60)
  CALL_COOLDOWN_SECONDS = (0..600)
  # Each routing setting an inbox saves, with the values it accepts
  CALL_ROUTING_SETTINGS = {
    'ring_strategy' => ->(value) { RING_STRATEGIES.include?(value) },
    'ring_step_seconds' => ->(value) { value.is_a?(Integer) && RING_STEP_SECONDS.cover?(value) },
    'prefer_free_agents' => ->(value) { [true, false].include?(value) },
    'call_cooldown_seconds' => ->(value) { value.is_a?(Integer) && CALL_COOLDOWN_SECONDS.cover?(value) }
  }.freeze

  def sequential_ringing? = provider_config['ring_strategy'] == 'sequential'

  def ring_step_seconds = provider_config.fetch('ring_step_seconds', DEFAULT_RING_STEP_SECONDS)

  # Agents on a call ring after the free ones
  def prefer_free_agents? = provider_config['prefer_free_agents'] == true

  # How long after an answered call an agent rings after the others
  def call_cooldown_seconds = provider_config.fetch('call_cooldown_seconds', 0)

  private

  def call_routing_settings_valid
    return if CALL_ROUTING_SETTINGS.all? { |key, valid| !provider_config.key?(key) || valid.call(provider_config[key]) }

    errors.add(:base, I18n.t('inbox.call_routing.invalid_settings', step_min: RING_STEP_SECONDS.min, step_max: RING_STEP_SECONDS.max,
                                                                    cooldown_max: CALL_COOLDOWN_SECONDS.max))
  end
end
