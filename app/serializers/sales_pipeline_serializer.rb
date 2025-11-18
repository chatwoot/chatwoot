class SalesPipelineSerializer < ActiveModel::Serializer
  attributes :id, :name, :created_at, :updated_at

  has_many :sales_pipeline_stages
end