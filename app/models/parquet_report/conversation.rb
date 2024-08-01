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
class ParquetReport::Conversation < ParquetReport
  def process!
    super

    url = Digitaltolk::ConversationsParquetService.new(@conversations, file_name, self).perform
    complete_and_save_url!(url)
  end

  def create_empty_file_url
    url = Digitaltolk::ConversationsParquetService.new([], file_name, self).perform
    update_columns(file_url: url)
    url
  end

  def load_records
    load_conversations
  end

  private

  def load_conversations
    prepare_attributes

    @conversations = account.conversations.filter_by_created_at(range)
  end
end
