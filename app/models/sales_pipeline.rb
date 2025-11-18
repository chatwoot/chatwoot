class SalesPipeline < ApplicationRecord
  belongs_to :account
  has_many :sales_pipeline_stages, -> { order(:position) }, dependent: :destroy, inverse_of: :sales_pipeline

  validates :name, presence: true, uniqueness: { scope: :account_id }

  after_create :create_default_stages

  default_scope { order(:name) }

  private

  def create_default_stages
    return if sales_pipeline_stages.exists?

    default_stages = [
      { name: 'Novo', color: '#6B7280', position: 1, is_default: true },
      { name: 'Qualificando', color: '#3B82F6', position: 2 },
      { name: 'Proposta', color: '#F59E0B', position: 3 },
      { name: 'Negociação', color: '#8B5CF6', position: 4 },
      { name: 'Fechado Ganhou', color: '#10B981', position: 5, is_closed_won: true },
      { name: 'Fechado Perdido', color: '#EF4444', position: 6, is_closed_lost: true }
    ]

    default_stages.each do |stage_data|
      ActiveRecord::Base.transaction do
        label = account.labels.create!(
          title: stage_data[:name],
          color: stage_data[:color],
          description: "Estágio do pipeline de vendas: #{stage_data[:name]}"
        )

        sales_pipeline_stages.create!(
          stage_data.merge(label_id: label.id)
        )
      end
    end
  end
end