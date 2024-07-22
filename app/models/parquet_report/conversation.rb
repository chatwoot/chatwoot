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
    load_conversations

    url = Digitaltolk::ConversationsParquetService.new(@conversations, file_name, self).perform
    complete_and_save_url!(url)
  end

  def create_empty_file_url
    Digitaltolk::ConversationsParquetService.new([], file_name, self).perform
  end

  private

  def load_conversations
    set_current_attributes
    conversation_finder = ConversationFinder.new(user, params)
    result = conversation_finder.perform
    @conversations = result[:conversations]
  end
end
