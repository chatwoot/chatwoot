# == Schema Information
#
# Table name: response_documents
#
#  id                 :bigint           not null, primary key
#  content            :text
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
#  index_response_documents_on_document            (document_type,document_id)
#  index_response_documents_on_response_source_id  (response_source_id)
#
class ResponseDocument < ApplicationRecord
  has_many :responses, dependent: :destroy
  belongs_to :account
  belongs_to :response_source

  before_validation :set_account
  after_update :handle_content_change

  private

  def set_account
    self.account = response_source.account
  end

  def handle_content_change
    return unless saved_change_to_content? && content_was.nil? && !content.nil?

    ResponseBuilderJob.perform_later(id)
  end
end
