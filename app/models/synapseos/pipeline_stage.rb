# == Schema Information
#
# Table name: synapseos_pipeline_stages
#
#  id         :bigint           not null, primary key
#  color      :string           default("#2196F3"), not null
#  name       :string           not null
#  position   :integer          default(0), not null
#  stage_type :string           default("custom"), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#
# Indexes
#
#  index_synapseos_pipeline_stages_on_account_id               (account_id)
#  index_synapseos_pipeline_stages_on_account_id_and_name      (account_id,name) UNIQUE
#  index_synapseos_pipeline_stages_on_account_id_and_position  (account_id,position)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
module Synapseos
  class PipelineStage < ApplicationRecord
    self.table_name = 'synapseos_pipeline_stages'

    STAGE_TYPES = %w[open inbound working won lost custom].freeze

    DEFAULT_STAGES = [
      { slug: 'entrada_pesquisa', name: 'Entrada & Pesquisa', color: '#6B7280', position: 1, stage_type: 'inbound',
        description: 'O lead chegou (inbound) ou foi mapeado (outbound). Faça a pesquisa inicial sobre a empresa/pessoa para não gastar perguntas de Situação à toa. Próximo passo obrigatório: agendar a primeira tentativa de contato (call/WhatsApp/email) com data e hora.' },
      { slug: 'conexao_situacao', name: 'Conexão & Situação', color: '#3B82F6', position: 2, stage_type: 'open',
        description: 'Primeiro contato estabelecido. Crie rapport e entenda o contexto atual (SPIN: Situação). Ex: "Como vocês gerenciam o processo X atualmente?" Gatilho de passagem: o lead aceita aprofundar a conversa. Próximo passo obrigatório: convite de calendário enviado e aceito para reunião de Discovery.' },
      { slug: 'diagnostico_dor', name: 'Diagnóstico de Dor', color: '#8B5CF6', position: 3, stage_type: 'working',
        description: 'Fase mais crítica — não apresente o produto ainda. Descubra o que está errado e faça o cliente sentir o peso do problema (SPIN: Problema & Implicação). Gatilho de passagem: o cliente admitiu que tem um problema urgente. Próximo passo obrigatório: agendar apresentação da solução.' },
      { slug: 'apresentacao_valor', name: 'Apresentação de Valor', color: '#F59E0B', position: 4, stage_type: 'working',
        description: 'Apresente a solução focada exclusivamente nos problemas mapeados (SPIN: Necessidade de Solução). Faça o cliente verbalizar o valor. Gatilho de passagem: o lead concorda que a solução resolve o problema e pede condições. Próximo passo obrigatório: elaborar e enviar proposta/contrato com prazo.' },
      { slug: 'proposta_negociacao', name: 'Proposta & Negociação', color: '#F97316', position: 5, stage_type: 'working',
        description: 'Proposta enviada. Contorne objeções finais (orçamento, prazos, aprovação). Regra de ouro: nunca envie proposta sem follow-up agendado. Ex: "Posso te ligar na quinta às 14h para tirar dúvidas?"' },
      { slug: 'fechado_ganho', name: 'Fechado Ganho', color: '#10B981', position: 6, stage_type: 'won',
        description: 'Contrato assinado. Próximo passo obrigatório: passagem de bastão para Customer Success ou Onboarding.' },
      { slug: 'perdido', name: 'Perdido', color: '#EF4444', position: 7, stage_type: 'lost',
        description: 'Registre o motivo de perda para calibrar suas perguntas SPIN no futuro. Próximo passo obrigatório: adicionar a uma cadência de nutrição para resgate em 3–6 meses.' }
    ].freeze

    belongs_to :account
    has_many :leads, class_name: 'Synapseos::Lead', foreign_key: :pipeline_stage_id, dependent: :nullify

    validates :name, presence: true, uniqueness: { scope: :account_id, case_sensitive: false }
    validates :stage_type, inclusion: { in: STAGE_TYPES }

    scope :ordered, -> { order(:position, :id) }

    def won?
      stage_type == 'won'
    end

    def lost?
      stage_type == 'lost'
    end
  end
end
