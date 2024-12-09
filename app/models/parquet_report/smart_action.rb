# == Schema Information
#
# Table name: smart_actions
#
#  id                :bigint           not null, primary key
#  active            :boolean          default(TRUE)
#  custom_attributes :jsonb
#  description       :string
#  event             :string
#  intent_type       :string
#  label             :string
#  name              :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  conversation_id   :bigint           not null
#  message_id        :bigint           not null
#
# Indexes
#
#  index_smart_actions_on_conversation_id  (conversation_id)
#  index_smart_actions_on_message_id       (message_id)
#
class ParquetReport::AgentScore < ParquetReport
  def process!
    super

    url = Digitaltolk::AgentScoreParquetService.new(@smart_actions, file_name, self).perform
    complete_and_save_url!(url)
  end

  def create_empty_file_url
    url = Digitaltolk::AgentScoreParquetService.new([], file_name, self).perform
    update_columns(file_url: url)
    url
  end

  def load_records
    load_smart_actions
  end

  private

  def load_smart_actions
    prepare_attributes

    @smart_actions = account.smart_actions.filter_by_created_at(range)
  end
end
