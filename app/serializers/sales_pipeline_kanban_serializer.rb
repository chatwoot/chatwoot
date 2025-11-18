class SalesPipelineKanbanSerializer < ActiveModel::Serializer
  attributes :stages

  def stages
    object.map do |stage_data|
      {
        stage_id: stage_data[:stage_id],
        name: stage_data[:name],
        color: stage_data[:color],
        position: stage_data[:position],
        is_default: stage_data[:is_default],
        is_closed_won: stage_data[:is_closed_won],
        is_closed_lost: stage_data[:is_closed_lost],
        cards_count: stage_data[:cards].count,
        cards: stage_data[:cards]
      }
    end
  end
end