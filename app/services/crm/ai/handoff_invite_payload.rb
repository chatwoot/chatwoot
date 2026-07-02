# Convite R3 em aberto como payload estável e seguro (epochs), usado pelo
# card do kanban (Cards::PayloadBuilder) e pela lista de conversas
# (Conversations::EventDataPresenter). Retorna nil quando não há convite
# ativo — o ciclo fechado (pega, cancelamento, expiração ou escalação)
# derruba o badge nos dois lugares.
class Crm::Ai::HandoffInvitePayload
  TERMINAL_KEYS = %w[picked_up_at canceled_at expired_at escalated_at].freeze

  def self.for_card(card)
    new(card).perform
  end

  def initialize(card)
    @card = card
  end

  def perform
    pointer = (@card.metadata || {}).dig('ai', 'handoff')
    return unless pointer.is_a?(Hash)
    return if pointer['invited_at'].blank?
    return if TERMINAL_KEYS.any? { |key| pointer[key].present? }

    invited_at = parse_time(pointer['invited_at'])
    return if invited_at.blank?

    { invited_at: invited_at.to_i, pickup_due_at: pickup_due_at(pointer, invited_at).to_i }
  end

  private

  def pickup_due_at(pointer, invited_at)
    due = parse_time(pointer['pickup_due_at'])
    return due if due.present?

    # Ciclos anteriores ao carimbo de pickup_due_at: resolve pela config efetiva.
    threshold = Crm::Ai::Config.handoff_settings(@card.stage, @card.pipeline)[:pickup_threshold_seconds].to_i
    invited_at + threshold.seconds
  end

  def parse_time(value)
    Time.zone.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end
end
