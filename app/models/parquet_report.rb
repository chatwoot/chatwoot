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
  after_create :set_pending_status

  belongs_to :account
  belongs_to :user, optional: true

  COMPLETED = 'completed'.freeze
  FAILED = 'failed'.freeze
  IN_PROGRESS = 'in_progress'.freeze
  PENDING = 'pending'.freeze

  def process!
    # Implement in subclass
  end

  def progress_url
    Rails.application.routes.url_helpers.api_v1_account_parquet_report_url(account_id: Current.account.id, id: id)
  end

  def create_empty_file_url
    # Implement in subclass
  end

  def complete_and_save_url!(url)
    update_columns(progress: 100, status: COMPLETED, file_url: url, elapse_time: Time.now - created_at)
  end

  def progress_json
    { 
      progress: progress,
      status: status,
      file_url: file_url,
      error_message: error_message,
      type: type,
      elapse_time: elapse_time,
      record_count: record_count
    }
  end

  def in_progress!(record_count: 0)
    update_columns(status: IN_PROGRESS, record_count: record_count)
  end

  def failed!(error_message)
    update_columns(status: FAILED, error_message: error_message)
  end

  def increment_progress(processed_count: 0)
    computed = (processed_count.to_f / record_count * 100).to_i
    update_columns(progress: computed, elapse_time: Time.now - created_at)
  end

  private

  def set_pending_status
    update_columns(status: PENDING)
  end

  def prepare_attributes
    Current.user = user
    Current.account = account
  end

  def accessible_params
    params.with_indifferent_access
  end

  def range
    return if accessible_params[:since].blank? || accessible_params[:until].blank?

    parse_date_time(accessible_params[:since])...parse_date_time(accessible_params[:until])
  end

  def parse_date_time(datetime)
    return datetime if datetime.is_a?(DateTime)
    return datetime.to_datetime if datetime.is_a?(Time) || datetime.is_a?(Date)

    begin
      DateTime.strptime(datetime, '%Y-%m-%d %H:%M')
    rescue
      DateTime.strptime(datetime, '%s')
    end
  end
end
