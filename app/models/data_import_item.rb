# == Schema Information
#
# Table name: data_import_items
#
#  id                   :bigint           not null, primary key
#  attempt_count        :integer          default(0), not null
#  chatwoot_record_type :string
#  last_error_code      :string
#  last_error_message   :text
#  metadata             :jsonb            not null
#  source_object_type   :string           not null
#  source_provider      :string           not null
#  status               :integer          default("pending"), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  chatwoot_record_id   :bigint
#  data_import_id       :bigint           not null
#  source_object_id     :string           not null
#
# Indexes
#
#  idx_data_import_items_on_import_and_source  (data_import_id,source_object_type,source_object_id) UNIQUE
#  idx_data_import_items_on_record             (chatwoot_record_type,chatwoot_record_id)
#  idx_data_import_items_on_source             (source_provider,source_object_type,source_object_id)
#  index_data_import_items_on_data_import_id   (data_import_id)
#
class DataImportItem < ApplicationRecord
  belongs_to :data_import
  has_many :import_errors, class_name: 'DataImportError', dependent: :destroy_async

  validates :source_provider, :source_object_type, :source_object_id, presence: true
  validates :source_object_id, uniqueness: { scope: [:data_import_id, :source_object_type] }

  enum status: { pending: 0, processing: 1, imported: 2, skipped: 3, failed: 4 }
end
