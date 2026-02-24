# == Schema Information
#
# Table name: contact_pipeline_stages
#
#  id                :bigint           not null, primary key
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  contact_id        :bigint           not null
#  pipeline_stage_id :bigint           not null
#  account_id        :bigint           not null
#
# Indexes
#
#  index_contact_pipeline_stages_on_account_id         (account_id)
#  index_contact_pipeline_stages_on_contact_id_and_pipeline_stage_id  (contact_id,pipeline_stage_id) UNIQUE
#  index_contact_pipeline_stages_on_pipeline_stage_id  (pipeline_stage_id)
#
class ContactPipelineStage < ApplicationRecord
  belongs_to :contact
  belongs_to :pipeline_stage
  belongs_to :account
end
