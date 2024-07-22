# == Schema Information
#
# Table name: parquet_reports
#
#  id            :bigint           not null, primary key
#  error_message :string
#  file_name     :string
#  file_url      :string
#  params        :jsonb
#  progress      :integer          default(0)
#  status        :string
#  type          :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :bigint           not null
#  user_id       :bigint
#
# Indexes
#
#  index_parquet_reports_on_account_id  (account_id)
#  index_parquet_reports_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (user_id => users.id)
#
class ParquetReport < ApplicationRecord
  include Sift
  include DateRangeHelper

  after_create :set_pending_status

  belongs_to :account
  belongs_to :user, optional: true

  def process!
    # Implement in subclass
  end

  def progress_url
    Rails.application.routes.url_helpers.api_v1_account_parquet_report_url(account_id: Current.account.id, id: id)
  end

  private

  def set_pending_status
    update(status: "pending")
  end

  def set_current_attributes
    Current.user = user
    Current.account = account
  end
end
