# == Schema Information
#
# Table name: response_documents
#
#  id                 :bigint           not null, primary key
#  content            :text             not null
#  document_link      :string
#  document_type      :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  account_id         :bigint           not null
#  document_id        :bigint
#  response_source_id :bigint           not null
#
# Indexes
#
#  index_response_documents_on_account_id_and_document_link  (account_id,document_link) UNIQUE
#  index_response_documents_on_document                      (document_type,document_id)
#  index_response_documents_on_response_source_id            (response_source_id)
#
class ResponseDocument < ApplicationRecord
  has_many :responses, dependent: :destroy
  belongs_to :account
  belongs_to :response_source

  after_update :handle_content_change

  private

  def handle_content_change
    return unless saved_change_to_content? && content_was.nil? && !content.nil?

    ResponseBuilderJob.perform_later(id)
  end
end
