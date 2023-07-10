# == Schema Information
#
# Table name: responses
#
#  id                   :bigint           not null, primary key
#  answer               :text             not null
#  question             :string           not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  account_id           :bigint           not null
#  response_document_id :bigint
#
# Indexes
#
#  index_responses_on_response_document_id  (response_document_id)
#
class Response < ApplicationRecord
  belongs_to :response_document
  belongs_to :account
end
