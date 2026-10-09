# == Schema Information
#
# Table name: data_exports
#
#  id                   :bigint           not null, primary key
#  artifacts_expired_at :datetime
#  completed_at         :datetime
#  data_type            :string           default("contacts"), not null
#  error_message        :text
#  export_options       :jsonb            not null
#  name                 :string           not null
#  notification_sent_at :datetime
#  processed_records    :integer          default(0), not null
#  started_at           :datetime
#  status               :integer          default("pending"), not null
#  total_records        :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  account_id           :bigint           not null
#  active_run_id        :string
#  initiated_by_id      :bigint
#
# Indexes
#
#  index_data_exports_on_account_id                 (account_id)
#  index_data_exports_on_account_id_and_created_at  (account_id,created_at)
#  index_data_exports_on_initiated_by_id            (initiated_by_id)
#  index_data_exports_on_status_and_updated_at      (status,updated_at)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (initiated_by_id => users.id) ON DELETE => nullify
#
class DataExport < ApplicationRecord
  belongs_to :account
  belongs_to :initiated_by, class_name: 'User', optional: true
  has_one_attached :export_file
  attr_readonly :account_id, :initiated_by_id, :export_options

  enum :status, { pending: 0, processing: 1, completed: 2, failed: 3 }

  validates :name, presence: true
  validates :data_type, inclusion: { in: ['contacts'] }
  validates :export_options, presence: true

  def stalled?
    (pending? || processing?) && updated_at <= DataImport::IMPORT_STALLED_AFTER.ago
  end

  def downloadable?
    completed? && artifacts_expired_at.nil? && export_file.attached?
  end

  def requester_authorized?
    membership = account.account_users.find_by(user_id: initiated_by_id)
    membership && ContactPolicy.new({ user: initiated_by, account: account, account_user: membership }, Contact).export?
  end
end
