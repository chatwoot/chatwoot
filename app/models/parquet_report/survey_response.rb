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
class ParquetReport::SurveyResponse < ParquetReport
  def process!
    load_surveys

    url = Digitaltolk::SurveyResponsesParquetService.new(@csat_survey_responses, file_name, self).perform
    complete_and_save_url!(url)
  end

  def create_empty_file_url
    Digitaltolk::SurveyResponsesParquetService.new([], file_name, self).perform
  end

  private

  def load_surveys
    set_current_attributes
    base_query = Current.account.csat_survey_responses.includes([:conversation, :assigned_agent, :contact])
    @csat_survey_responses = filtrate(base_query).filter_by_created_at(range)
                                                 .filter_by_assigned_agent_id(params[:user_ids])
                                                 .filter_by_inbox_id(params[:inbox_id])
                                                 .filter_by_team_id(params[:team_id])
                                                 .filter_by_rating(params[:rating])
                                                 .filter_by_label(params[:label])
                                                 .filter_by_question(params[:question])
  end
end
