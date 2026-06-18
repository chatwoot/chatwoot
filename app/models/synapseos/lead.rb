# == Schema Information
#
# Table name: synapseos_leads
#
#  id                :bigint           not null, primary key
#  cadence_touch     :integer          default(0), not null
#  disqualified_at   :datetime
#  estado            :string
#  forma_pagamento   :string
#  horizonte_compra  :string
#  metadata          :jsonb            not null
#  modelo_interesse  :string
#  motivo            :text
#  next_action_at    :datetime
#  qualified_at      :datetime
#  retomada_at       :datetime
#  source            :string
#  status            :integer          default("open"), not null
#  tem_troca         :boolean
#  urgencia          :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :bigint           not null
#  assignee_id       :bigint
#  contact_id        :bigint
#  conversation_id   :bigint           not null
#  pipeline_stage_id :bigint
#
# Indexes
#
#  idx_synapseos_leads_stage_time                           (account_id,pipeline_stage_id,created_at)
#  index_synapseos_leads_on_account_id                      (account_id)
#  index_synapseos_leads_on_account_id_and_conversation_id  (account_id,conversation_id) UNIQUE
#  index_synapseos_leads_on_account_id_and_created_at       (account_id,created_at)
#  index_synapseos_leads_on_account_id_and_status           (account_id,status)
#  index_synapseos_leads_on_assignee_id                     (assignee_id)
#  index_synapseos_leads_on_contact_id                      (contact_id)
#  index_synapseos_leads_on_conversation_id                 (conversation_id)
#  index_synapseos_leads_on_pipeline_stage_id               (pipeline_stage_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (assignee_id => users.id)
#  fk_rails_...  (contact_id => contacts.id)
#  fk_rails_...  (conversation_id => conversations.id)
#  fk_rails_...  (pipeline_stage_id => synapseos_pipeline_stages.id)
#
module Synapseos
  class Lead < ApplicationRecord
    self.table_name = 'synapseos_leads'

    belongs_to :account
    belongs_to :conversation
    belongs_to :contact, optional: true
    belongs_to :assignee, class_name: 'User', optional: true
    belongs_to :pipeline_stage, class_name: 'Synapseos::PipelineStage', optional: true

    has_many :deals, class_name: 'Synapseos::Deal', dependent: :destroy

    enum status: { open: 0, qualified: 1, disqualified: 2, converted: 3 }

    # ADR-003: estado de 1ª classe da máquina de ciclo de vida. String (não
    # enum integer) por compat com leads legados (estado nil) e legibilidade no
    # banco. `nao_quer` é o único estado terminal.
    # ADR-003 (estendido): além dos 4 estados do funil comercial, pos_venda e
    # outros — cliente que precisa de uma PESSOA mas NÃO é venda (roteado pro
    # humano via webhook do n8n). Não-terminais: precisam de atendimento, então
    # têm SLA (next_action_at) como o 'quer'.
    ESTADOS = %w[quer quer_depois nao_quer sem_resposta pos_venda outros].freeze
    TERMINAL_ESTADOS = %w[nao_quer].freeze

    validates :status, presence: true
    validates :conversation_id, uniqueness: { scope: :account_id }
    validates :estado, inclusion: { in: ESTADOS }, allow_nil: true

    # I2 — Nenhum lead fica sem próximo toque agendado: todo lead num estado
    # não-terminal DEVE ter next_action_at. Leads legados sem estado (nil) ficam
    # de fora — a invariante só vale depois da 1ª transição.
    validate :non_terminal_requires_next_action

    # I1 — Desfecho terminal exige motivo registrado.
    validate :terminal_requires_motivo

    after_update :sync_deal_with_stage, if: :saved_change_to_pipeline_stage_id?

    def terminal?
      TERMINAL_ESTADOS.include?(estado)
    end

    private

    def non_terminal_requires_next_action
      return if estado.blank? # lead legado, ainda não entrou na máquina
      return if terminal?
      return if next_action_at.present?

      errors.add(:next_action_at, 'é obrigatório para leads em estado não-terminal (I2)')
    end

    def terminal_requires_motivo
      return unless terminal?
      return if motivo.present?

      errors.add(:motivo, 'é obrigatório para desfecho terminal (I1)')
    end

    def sync_deal_with_stage
      stage = pipeline_stage
      return if stage.nil?

      if stage.won?
        target_deal.update!(status: :won, closed_at: target_deal.closed_at || Time.current)
        log_crm_event('deal_won', deal_id: target_deal.id)
      elsif stage.lost?
        target_deal.update!(status: :lost, closed_at: target_deal.closed_at || Time.current)
        log_crm_event('deal_lost', deal_id: target_deal.id)
      end
    end

    def target_deal
      @target_deal ||= deals.order(:created_at).last ||
                       ::Synapseos::Deal.create!(
                         account_id: account_id,
                         lead_id: id,
                         assignee_id: assignee_id,
                         status: :pending,
                         amount: 0,
                         metadata: { source: 'pipeline_stage_change' }
                       )
    end

    def log_crm_event(event_type, metadata = {})
      ::Synapseos::CrmEvent.create!(
        account_id: account_id,
        conversation_id: conversation_id,
        event_type: event_type,
        metadata: metadata.merge(source: 'pipeline_stage', stage: pipeline_stage&.name)
      )
    end
  end
end
