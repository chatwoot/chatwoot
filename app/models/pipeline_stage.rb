# == Schema Information
#
# Table name: pipeline_stages
#
#  id          :bigint           not null, primary key
#  name        :string           not null
#  position    :integer          default(0)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  pipeline_id :bigint           not null
#
# Indexes
#
#  index_pipeline_stages_on_pipeline_id  (pipeline_id)
#

class PipelineStage < ApplicationRecord
  belongs_to :pipeline
  has_many :deals, dependent: :nullify

  validates :name, presence: true
  validates :position, presence: true

  acts_as_list scope: :pipeline if respond_to?(:acts_as_list)
end
