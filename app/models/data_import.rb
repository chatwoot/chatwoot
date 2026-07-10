# == Schema Information
#
# Table name: data_imports
#
#  id                :bigint           not null, primary key
#  abandoned_at      :datetime
#  access_token      :text
#  completed_at      :datetime
#  cursor            :jsonb            not null
#  data_type         :string           not null
#  import_types      :jsonb            not null
#  last_error_at     :datetime
#  name              :string
#  processed_records :integer
#  processing_errors :text
#  source_metadata   :jsonb            not null
#  source_provider   :string
#  source_type       :string
#  started_at        :datetime
#  stats             :jsonb            not null
#  status            :integer          default("pending"), not null
#  total_records     :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :bigint           not null
#  initiated_by_id   :integer
#
# Indexes
#
#  index_data_imports_on_account_id       (account_id)
#  index_data_imports_on_initiated_by_id  (initiated_by_id)
#  index_data_imports_on_source_provider  (source_provider)
#
class DataImport < ApplicationRecord
  ACTIVE_INTERCOM_IMPORT_RUN_ID_KEY = 'active_intercom_import_run_id'.freeze
  LEGACY_DATA_TYPES = ['contacts'].freeze
  INTEGRATION_DATA_TYPES = ['intercom'].freeze
  IMPORT_TYPES = %w[contacts conversations].freeze

  belongs_to :account
  belongs_to :initiated_by, class_name: 'User', optional: true

  encrypts :access_token if Chatwoot.encryption_configured?

  has_many :items, class_name: 'DataImportItem', dependent: :destroy_async
  has_many :mappings, class_name: 'DataImportMapping', dependent: :destroy_async
  has_many :import_errors, class_name: 'DataImportError', dependent: :destroy_async

  validates :data_type, inclusion: { in: LEGACY_DATA_TYPES + INTEGRATION_DATA_TYPES, message: I18n.t('errors.data_import.data_type.invalid') }
  validates :access_token, presence: true, on: :create, if: :intercom_import?
  validate :validate_import_types

  enum status: { pending: 0, processing: 1, completed: 2, failed: 3, completed_with_errors: 6, abandoned: 7 }

  scope :active_intercom, -> { where(data_type: 'intercom', source_provider: 'intercom', status: [:pending, :processing]) }

  has_one_attached :import_file
  has_one_attached :failed_records

  after_create_commit :process_data_import

  def legacy_contacts_csv_import?
    data_type == 'contacts' && source_provider.blank?
  end

  def intercom_import?
    data_type == 'intercom' && source_provider == 'intercom'
  end

  def restartable?
    failed? || abandoned?
  end

  def abandonable?
    intercom_import? && (pending? || processing?)
  end

  def abandon!
    self.class.transaction do
      abandonable_import = self.class.lock.find_by(
        id: id,
        data_type: 'intercom',
        source_provider: 'intercom',
        status: [:pending, :processing]
      )
      abandonable_import&.update!(status: :abandoned, abandoned_at: Time.current)
    end
    reload
  end

  def active_intercom_import_run_id
    source_metadata.to_h[ACTIVE_INTERCOM_IMPORT_RUN_ID_KEY]
  end

  def assign_active_intercom_import_run_id
    self.source_metadata = source_metadata.to_h.merge(ACTIVE_INTERCOM_IMPORT_RUN_ID_KEY => SecureRandom.uuid)
    active_intercom_import_run_id
  end

  private

  def process_data_import
    return unless legacy_contacts_csv_import?

    # we wait for the file to be uploaded to the cloud
    DataImportJob.set(wait: 1.minute).perform_later(self)
  end

  def validate_import_types
    return if import_types.blank?

    invalid_types = import_types - IMPORT_TYPES
    return if invalid_types.blank?

    errors.add(:import_types, "contains unsupported values: #{invalid_types.join(', ')}")
  end
end
