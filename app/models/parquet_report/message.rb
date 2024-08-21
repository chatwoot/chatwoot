# == Schema Information
#
# Table name: parquet_reports
#
#  id            :bigint           not null, primary key
#  elapse_time   :integer          default(0)
#  error_message :string
#  file_name     :string
#  file_url      :string
#  params        :jsonb
#  progress      :integer          default(0)
#  record_count  :integer          default(0)
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
class ParquetReport::Message < ParquetReport
  def process!
    super
    url = Digitaltolk::MessagesParquetService.new(@messages, file_name, self).perform
    complete_and_save_url!(url)
  end

  def create_empty_file_url
    url = Digitaltolk::MessagesParquetService.new([], file_name, self).perform
    update_columns(file_url: url)
    url
  end

  def load_records
    load_messages
  end

  private

  def load_messages
    prepare_attributes
    base_query = account.messages.includes(:inbox, :conversation)
    @messages = base_query.filter_by_created_at(range)
                          .filter_by_inbox(accessible_params[:inbox_id])
                          .filter_by_team(accessible_params[:team_id])
                          .filter_by_label(accessible_params[:label])
                          .order(created_at: :desc)
  end
end
