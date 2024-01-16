# == Schema Information
#
# Table name: data_imports
#
#  id                :bigint           not null, primary key
#  data_type         :string           not null
#  processed_records :integer
#  processing_errors :text
#  status            :integer          default("pending"), not null
#  total_records     :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :bigint           not null
#
# Indexes
#
#  index_data_imports_on_account_id  (account_id)
#
class DataImport < ApplicationRecord
  belongs_to :account
  validates :data_type, inclusion: { in: ['contacts'], message: I18n.t('errors.data_import.data_type.invalid') }
  enum status: { pending: 0, processing: 1, completed: 2, failed: 3 }

  has_one_attached :import_file
  has_one_attached :failed_records

  after_create_commit :process_data_import

  private

  def process_data_import
    # we wait for the file to be uploaded to the cloud
    DataImportJob.set(wait: 1.minute).perform_later(self)
  end
end
