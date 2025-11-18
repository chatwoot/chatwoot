class SalesPipelineStageSerializer < ActiveModel::Serializer
  attributes :id, :name, :color, :position, :is_default, :is_closed_won, :is_closed_lost, :created_at, :updated_at

  belongs_to :label
  belongs_to :sales_pipeline
end