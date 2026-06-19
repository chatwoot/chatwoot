# == Schema Information
#
# Table name: synapseos_crm_events
#
#  id              :bigint           not null, primary key
#  event_type      :string           not null
#  metadata        :jsonb            not null
#  created_at      :datetime         not null
#  account_id      :bigint           not null
#  conversation_id :bigint
#  user_id         :bigint
#
# Indexes
#
#  idx_synapseos_crm_events_conv_time             (account_id,conversation_id,created_at)
#  idx_synapseos_crm_events_type_time             (account_id,event_type,created_at)
#  index_synapseos_crm_events_on_account_id       (account_id)
#  index_synapseos_crm_events_on_conversation_id  (conversation_id)
#  index_synapseos_crm_events_on_user_id          (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (conversation_id => conversations.id)
#  fk_rails_...  (user_id => users.id)
#
module Synapseos
  class CrmEvent < ApplicationRecord
    self.table_name = 'synapseos_crm_events'

    # Append-only audit log; updates are not allowed.
    EVENT_TYPES = %w[
      lead_created
      lead_qualified
      lead_disqualified
      deal_created
      deal_won
      deal_lost
      bot_takeover
      human_rescue
      appointment
      appointment_confirmed
      pix_sent
      lead_rescued
      private_note_added
      sales_alert_dispatched
      sales_alert_approved
      lead_blocked
      lead_state_changed
      dry_run_snapshot
    ].freeze

    belongs_to :account
    belongs_to :conversation, optional: true
    belongs_to :user, optional: true

    validates :event_type, presence: true, inclusion: { in: EVENT_TYPES }

    after_create_commit :emit_timeline_activity
    after_create_commit :broadcast_synapseos_event

    TIMELINE_EVENT_TYPES = %w[
      bot_takeover
      human_rescue
      appointment_confirmed
      lead_qualified
      deal_won
      deal_lost
      sales_alert_dispatched
      lead_blocked
      lead_state_changed
    ].freeze

    private

    def broadcast_synapseos_event
      Rails.configuration.dispatcher.dispatch(
        ::Events::Types::SYNAPSEOS_CRM_EVENT_CREATED,
        Time.zone.now,
        crm_event: self
      )
    end

    def emit_timeline_activity
      return if conversation_id.blank?
      return unless TIMELINE_EVENT_TYPES.include?(event_type)

      conversation.messages.create!(
        account_id: account_id,
        inbox_id: conversation.inbox_id,
        message_type: :activity,
        content: timeline_content
      )
    rescue StandardError => e
      Rails.logger.warn("[Synapseos::CrmEvent] could not emit timeline activity: #{e.message}")
    end

    def timeline_content
      case event_type
      when 'appointment_confirmed'
        date = metadata['date'] || metadata[:date]
        date.present? ? "📅 Agendamento confirmado para #{date}" : '📅 Agendamento confirmado'
      when 'bot_takeover'
        '🤖 ➜ 👤 Atendimento assumido por humano'
      when 'human_rescue'
        '👤 ➜ 🤖 Atendimento retomado pelo bot'
      when 'lead_qualified'
        '⭐ Lead qualificado'
      when 'deal_won'
        "✅ Negócio fechado (ganho) — #{metadata['amount'] || metadata[:amount] || ''}".strip
      when 'deal_lost'
        '❌ Negócio perdido'
      when 'sales_alert_dispatched'
        modelo = metadata['modelo_interesse'] || metadata[:modelo_interesse]
        modelo.present? ? "🚨 Alerta de venda disparado (#{modelo})" : '🚨 Alerta de venda disparado'
      when 'lead_blocked'
        motivo = metadata['motivo'] || metadata[:motivo]
        motivo.present? ? "🚫 Lead bloqueou contato (#{motivo[0..60]})" : '🚫 Lead bloqueou contato'
      when 'lead_state_changed'
        to = metadata['to'] || metadata[:to]
        labels = {
          'quer' => '⭐ Quer (alerta de venda)',
          'quer_depois' => '🕒 Quer depois (Futuro)',
          'nao_quer' => '🚫 Não quer (encerrado)',
          'sem_resposta' => '🔇 Sem resposta (cadência)'
        }
        labels[to] || "Estado do lead: #{to}"
      else
        "Evento: #{event_type}"
      end
    end
  end
end
