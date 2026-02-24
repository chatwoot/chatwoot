# == Schema Information
#
# Table name: pipeline_stages
#
#  id         :bigint           not null, primary key
#  title      :string           not null
#  position   :integer          default(0), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  label_id   :bigint           not null
#
# Indexes
#
#  index_pipeline_stages_on_label_id               (label_id)
#  index_pipeline_stages_on_label_id_and_position   (label_id,position)
#  index_pipeline_stages_on_label_id_and_title      (label_id,title) UNIQUE
#
class PipelineStage < ApplicationRecord
  belongs_to :label, touch: true
  has_many :contact_pipeline_stages, dependent: :destroy

  validates :title, presence: true, uniqueness: { scope: :label_id }
  validates :position, presence: true

  default_scope { order(:position) }
end
