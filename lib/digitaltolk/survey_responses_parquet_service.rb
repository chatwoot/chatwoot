require 'parquet'

class Digitaltolk::SurveyResponsesParquetService
  attr_accessor :survey_responses, :file_name, :report

  def initialize(survey_responses, file_name, report)
    @survey_responses = survey_responses
    @file_name = file_name
    @report = report
  end

  # @return [Hash]
  def perform
    report.in_progress!(record_count: record_count)
    export_parquet
  rescue StandardError => e
    report.failed!(e.message)
    nil
  end

  private

  def file_path
    @file_path ||= Rails.root.join('tmp', file_name)
  end

  def arrow_fields
    [
      Arrow::Field.new('id', :int32),
      Arrow::Field.new('rating', :int32),
      Arrow::Field.new('feedback_message', :string),
      Arrow::Field.new('account_id', :int32),
      Arrow::Field.new('message_id', :int32),
      Arrow::Field.new('csat_question_id', :int32),
      Arrow::Field.new('csat_question', :string),
      Arrow::Field.new('contact_id', :int32),
      Arrow::Field.new('contact_name', :string),
      Arrow::Field.new('contact_email', :string),
      Arrow::Field.new('conversation_id', :int32),
      Arrow::Field.new('assigned_agent_id', :int32),
      Arrow::Field.new('assigned_agent_name', :string),
      Arrow::Field.new('assigned_agent_email', :string),
      Arrow::Field.new('created_at', :int32)
    ]
  end

  def arrow_schema
    Arrow::Schema.new(arrow_fields)
  end

  def initialize_columns
    @columns = {}

    arrow_fields.each do |f|
      @columns[f.name] = []
    end
  end

  def load_columns_data
    return if survey_responses.blank?

    index = 1
    batch_size = 100
    GC.enable
    survey_responses.find_in_batches(batch_size: batch_size) do |responses|
      responses.each do |survey_response|
        @columns['id'] << survey_response&.id.to_i
        @columns['rating'] << survey_response&.rating.to_i
        @columns['feedback_message'] << survey_response&.feedback_message.to_s
        @columns['account_id'] << survey_response&.account_id.to_i
        @columns['message_id'] << survey_response&.message_id.to_i
        @columns['csat_question_id'] << survey_response&.message&.csat_template_question&.id.to_i
        @columns['csat_question'] << csat_question(survey_response).to_s
        @columns['contact_id'] << survey_response&.contact&.id.to_i
        @columns['contact_name'] << survey_response&.contact&.name.to_s
        @columns['contact_email'] << survey_response&.contact&.email.to_s
        @columns['conversation_id'] << survey_response&.conversation&.display_id.to_i
        @columns['assigned_agent_id'] << survey_response&.assigned_agent&.id.to_i
        @columns['assigned_agent_name'] << survey_response&.assigned_agent&.name.to_s
        @columns['assigned_agent_email'] << survey_response&.assigned_agent&.email.to_s
        @columns['created_at'] << survey_response&.created_at.to_i
      end
      report.increment_progress(processed_count: index * batch_size)
      index += 1
      responses = nil
      GC.start
    end
  end

  def record_count
    (@record_count ||= @survey_responses.count).to_i
  end

  def map_columns_array
    [
      Arrow::Int32Array.new(@columns['id']),
      Arrow::Int32Array.new(@columns['rating']),
      Arrow::StringArray.new(@columns['feedback_message']),
      Arrow::Int32Array.new(@columns['account_id']),
      Arrow::Int32Array.new(@columns['message_id']),
      Arrow::Int32Array.new(@columns['csat_question_id']),
      Arrow::StringArray.new(@columns['csat_question']),
      Arrow::Int32Array.new(@columns['contact_id']),
      Arrow::StringArray.new(@columns['contact_name']),
      Arrow::StringArray.new(@columns['contact_email']),
      Arrow::Int32Array.new(@columns['conversation_id']),
      Arrow::Int32Array.new(@columns['assigned_agent_id']),
      Arrow::StringArray.new(@columns['assigned_agent_name']),
      Arrow::StringArray.new(@columns['assigned_agent_email']),
      Arrow::Int32Array.new(@columns['created_at'])
    ]
  end

  def arrow_columns
    initialize_columns
    load_columns_data
    map_columns_array
  end

  def export_parquet
    record_batch = Arrow::RecordBatch.new(arrow_schema, record_count, arrow_columns)
    record_batch.to_table.save(file_path)

    url = Digitaltolk::UploadToS3.new(file_path).perform

    # Delete the file after upload
    File.delete(file_path) rescue nil
    url
  end

  def csat_question(survey_response)
    survey_response&.message&.csat_template_question&.content.to_s || survey_response&.message&.content.to_s
  end
end