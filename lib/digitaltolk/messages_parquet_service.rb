require 'parquet'

class Digitaltolk::MessagesParquetService
  attr_accessor :messages, :file_name

  def initialize(messages, file_name)
    @messages = messages
    @file_name = file_name
  end

  # @return [Hash]
  def perform
    process_upload
  end

  private

  def process_upload
    export_parquet
  end

  def file_path
    @file_path ||= Rails.root.join('tmp', file_name)
  end

  def arrow_fields
    [
      Arrow::Field.new('id', :int32),
      Arrow::Field.new('content', :string),
      Arrow::Field.new('inbox_id', :int32),
      Arrow::Field.new('conversation_id', :int32),
      Arrow::Field.new('message_type', :string),
      Arrow::Field.new('content_type', :string),
      Arrow::Field.new('status', :string),
      Arrow::Field.new('created_at', :int32),
      Arrow::Field.new('private', :boolean),
      Arrow::Field.new('source_id', :int32)
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
    messages.each do |message|
      @columns['id'] << message.id
      @columns['content'] << message.content
      @columns['inbox_id'] << message.inbox_id
      @columns['conversation_id'] << message.conversation.display_id
      @columns['message_type'] << message.message_type_before_type_cast
      @columns['content_type'] << message.content_type
      @columns['status'] << message.status
      @columns['created_at'] << message.created_at.to_i
      @columns['private'] << message.private
      @columns['source_id'] << message.source_id
    end
  end

  def map_columns_array
    [
      Arrow::Int32Array.new(@columns['id']),
      Arrow::StringArray.new(@columns['content']),
      Arrow::Int32Array.new(@columns['inbox_id']),
      Arrow::Int32Array.new(@columns['conversation_id']),
      Arrow::StringArray.new(@columns['message_type']),
      Arrow::StringArray.new(@columns['content_type']),
      Arrow::StringArray.new(@columns['status']),
      Arrow::Int32Array.new(@columns['created_at']),
      Arrow::BooleanArray.new(@columns['private']),
      Arrow::Int32Array.new(@columns['source_id'])
    ]
  end

  def arrow_columns
    initialize_columns
    load_columns_data
    map_columns_array
  end

  def export_parquet
    record_batch = Arrow::RecordBatch.new(arrow_schema, @messages.count, arrow_columns)
    record_batch.to_table.save(file_path)

    url = Digitaltolk::UploadToS3.new(file_path).perform

    # Delete the file after upload
    File.delete(file_path) rescue nil
    url
  end

  def export_empty_file
  end
end