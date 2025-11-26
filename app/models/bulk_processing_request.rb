# == Schema Information
#
# Table name: bulk_processing_requests
#
#  id                :bigint           not null, primary key
#  dismissed_at      :datetime
#  entity_type       :string           not null
#  error_details     :jsonb
#  error_message     :text
#  failed_records    :integer          default(0)
#  file_name         :string
#  operation_type    :string           default("upload")
#  processed_records :integer          default(0)
#  progress          :decimal(5, 2)    default(0.0)
#  status            :string           default("pending"), not null
#  total_records     :integer          default(0)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :bigint           not null
#  job_id            :string
#  user_id           :bigint           not null
#
# Indexes
#
#  index_bulk_processing_requests_on_account_id      (account_id)
#  index_bulk_processing_requests_on_created_at      (created_at)
#  index_bulk_processing_requests_on_operation_type  (operation_type)
#  index_bulk_processing_requests_on_status          (status)
#  index_bulk_processing_requests_on_user_id         (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (user_id => users.id)
#
class BulkProcessingRequest < ApplicationRecord
  belongs_to :account
  belongs_to :user
  has_many :product_catalogs, dependent: :nullify

  validates :account_id, presence: true
  validates :user_id, presence: true
  validates :entity_type, presence: true
  validates :status, presence: true
  validates :progress, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :total_records, numericality: { greater_than_or_equal_to: 0 }
  validates :processed_records, numericality: { greater_than_or_equal_to: 0 }
  validates :failed_records, numericality: { greater_than_or_equal_to: 0 }

  enum status: {
    pending: 'PENDING',
    processing: 'PROCESSING',
    completed: 'COMPLETED',
    failed: 'FAILED',
    partially_completed: 'PARTIALLY_COMPLETED',
    cancelled: 'CANCELLED'
  }

  enum operation_type: {
    upload: 'UPLOAD',
    export: 'EXPORT',
    bulk_delete: 'DELETE'
  }, _prefix: :operation

  has_one_attached :export_file
  has_many_attached :export_files

  def update_progress(processed:, failed: 0)
    increment!(:processed_records, processed)
    increment!(:failed_records, failed)

    new_progress = (processed_records.to_f / total_records * 100).round(2)
    update!(progress: new_progress)

    check_completion_status
  end

  private

  def check_completion_status
    return unless processed_records + failed_records >= total_records

    if failed_records.zero?
      completed!
    elsif processed_records.positive?
      partially_completed!
    else
      failed!
    end
  end
end
