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
      { slug: 'novo_lead',      name: 'Novo Lead',      color: '#6B7280', position: 1, stage_type: 'open' },
      { slug: 'qualificado',    name: 'Qualificado',    color: '#3B82F6', position: 2, stage_type: 'open' },
      { slug: 'negociacao',     name: 'Negociação',     color: '#F59E0B', position: 3, stage_type: 'open' },
      { slug: 'fechado_ganho',  name: 'Fechado Ganho',  color: '#10B981', position: 4, stage_type: 'won' },
      { slug: 'perdido',        name: 'Perdido',        color: '#EF4444', position: 5, stage_type: 'lost' }
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
