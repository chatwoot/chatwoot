# == Schema Information
#
# Table name: data_import_errors
#
#  id                  :bigint           not null, primary key
#  details             :jsonb            not null
#  error_code          :string           not null
#  message             :text
#  source_object_type  :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  data_import_id      :bigint           not null
#  data_import_item_id :bigint
#  source_object_id    :string
#
# Indexes
#
#  idx_data_import_errors_on_source                 (source_object_type,source_object_id)
#  index_data_import_errors_on_data_import_id       (data_import_id)
#  index_data_import_errors_on_data_import_item_id  (data_import_item_id)
#
class DataImportError < ApplicationRecord
  SKIP_LOG_KINDS = %w[failed skipped].freeze

  belongs_to :data_import
  belongs_to :data_import_item, optional: true

  validates :error_code, presence: true

  scope :skip_logs, -> { where("details ->> 'kind' IN (:kinds)", kinds: SKIP_LOG_KINDS) }
  scope :failed, -> { where("details ->> 'kind' = ?", 'failed') }
  scope :non_skip_logs, -> { where("details ->> 'kind' IS NULL OR details ->> 'kind' NOT IN (:kinds)", kinds: SKIP_LOG_KINDS) }
end
