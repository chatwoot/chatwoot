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
class ParquetReport::Message < ParquetReport
  def process!
    load_messages

    if @messages.present?
      url = Digitaltolk::MessagesParquetService.new(@messages, file_name, self).perform
      update_columns(progress: 100, status: 'completed', file_url: url)
    end
  end

  private

  def load_messages
    set_current_attributes
    base_query = account.messages.includes(:inbox, :conversation)
    @messages = filtrate(base_query).filter_by_created_at(range)
                                    .filter_by_inbox(params[:inbox_id])
                                    .filter_by_team(params[:team_id])
                                    .filter_by_label(params[:label])
                                    .order(created_at: :desc)
  end
end
