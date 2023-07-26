# == Schema Information
#
# Table name: response_sources
#
#  id                :bigint           not null, primary key
#  name              :string           not null
#  source_link       :string
#  source_model_type :string
#  source_type       :integer          default("external"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :bigint           not null
#  inbox_id          :bigint           not null
#  source_model_id   :bigint
#
# Indexes
#
#  index_response_sources_on_source_model  (source_model_type,source_model_id)
#
class ResponseSource < ApplicationRecord
  enum source_type: { external: 0, kbase: 1, inbox: 2 }
  belongs_to :account
  belongs_to :inbox
  has_many :response_documents, dependent: :destroy
  has_many :responses, through: :response_documents

  accepts_nested_attributes_for :response_documents
end
