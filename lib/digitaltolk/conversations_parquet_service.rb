require 'parquet'

class Digitaltolk::ConversationsParquetService
attr_accessor :conversations, :file_name, :report

  def initialize(conversations, file_name, report)
    @conversations = conversations
    @report = report
    @file_name = file_name
  end

  def file_path
    @file_path ||= Rails.root.join('tmp', file_name)
  end

  def perform
    report.in_progress!(record_count: record_count)
    export_parquet
  rescue StandardError => e
    report.failed!("#{e.message}: #{e.backtrace.first}")
    nil
  end

  private

  def arrow_fields
    [
      Arrow::Field.new('id', :int64),
      Arrow::Field.new('sender_id', :int64),
      Arrow::Field.new('sender_name', :string),
      Arrow::Field.new('sender_email', :string),
      Arrow::Field.new('channel_type', :string),
      Arrow::Field.new('assignee_id', :int64),
      Arrow::Field.new('assignee_name', :string),
      Arrow::Field.new('assignee_email', :string),
      Arrow::Field.new('team_id', :int64),
      Arrow::Field.new('team_name', :string),
      Arrow::Field.new('account_id', :int64),
      Arrow::Field.new('additional_attributes', :string),
      Arrow::Field.new('contact_last_seen_at', :int64),
      Arrow::Field.new('custom_attributes', :string),
      Arrow::Field.new('inbox_id', :int64),
      Arrow::Field.new('inbox_name', :string),
      Arrow::Field.new('labels', :string),
      Arrow::Field.new('muted', :boolean),
      Arrow::Field.new('snoozed_until', :int64),
      Arrow::Field.new('status', :string),
      Arrow::Field.new('closed', :boolean),
      Arrow::Field.new('created_at', :int64),
      Arrow::Field.new('timestamp', :int64),
      Arrow::Field.new('first_reply_created_at', :int64),
      Arrow::Field.new('unread_count', :int64),
      Arrow::Field.new('last_non_activity_message', :string),
      Arrow::Field.new('last_activity_at', :int64),
      Arrow::Field.new('priority', :string),
      Arrow::Field.new('contact_kind', :string)
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
    return if conversations.is_a?(Array) && conversations.blank?
    return unless conversations.exists?

    index = 1
    batch_size = 100
    GC.enable
    conversations.find_in_batches(batch_size: batch_size) do |cons|
      cons.each do |conversation|
        @columns['id'] << conversation&.display_id.to_i
        @columns['sender_id'] << conversation&.contact&.id.to_i
        @columns['sender_name'] << conversation&.contact&.name.to_s
        @columns['sender_email'] << conversation&.contact&.email.to_s
        @columns['channel_type'] << conversation&.inbox&.channel_type.to_s
        @columns['assignee_id'] << conversation&.assignee&.id.to_i
        @columns['assignee_name'] << conversation&.assignee&.name.to_s
        @columns['assignee_email'] << conversation&.assignee&.email.to_s
        @columns['team_id'] << conversation&.team&.id.to_i
        @columns['team_name'] << conversation&.team&.name.to_s
        @columns['account_id'] << conversation&.account_id.to_i
        @columns['additional_attributes'] << conversation&.additional_attributes.to_s
        @columns['contact_last_seen_at'] << conversation&.contact_last_seen_at.to_i
        @columns['custom_attributes'] << conversation&.custom_attributes.to_s
        @columns['inbox_id'] << conversation&.inbox_id.to_i
        @columns['inbox_name'] << conversation&.inbox&.name.to_s
        @columns['labels'] << (conversation.present? ? conversation.cached_label_list_array.join(',').to_s : '')
        @columns['muted'] << !!(conversation&.muted?)
        @columns['snoozed_until'] << conversation&.snoozed_until.to_i
        @columns['status'] << conversation&.status.to_s
        @columns['closed'] << !!(conversation&.closed)
        @columns['created_at'] << conversation&.created_at.to_i
        @columns['timestamp'] << conversation&.last_activity_at.to_i
        @columns['first_reply_created_at'] << conversation&.first_reply_created_at.to_i
        @columns['unread_count'] << conversation&.unread_incoming_messages.count
        @columns['last_non_activity_message'] << (conversation.present? ? conversation.messages.non_activity_messages.first&.content.to_s : '')
        @columns['last_activity_at'] << conversation&.last_activity_at.to_i
        @columns['priority'] << conversation&.priority.to_s
        @columns['contact_kind'] << conversation&.contact_kind.to_s
      end
      report.increment_progress(processed_count: index * batch_size)
      cons = nil
      index += 1
      GC.start
    end
  end

  def record_count
    (@record_count ||= @conversations.count).to_i
  end

  def map_columns_array
    [
      Arrow::Int64Array.new(@columns['id']),
      Arrow::Int64Array.new(@columns['sender_id']),
      Arrow::StringArray.new(@columns['sender_name']),
      Arrow::StringArray.new(@columns['sender_email']),
      Arrow::StringArray.new(@columns['channel_type']),
      Arrow::Int64Array.new(@columns['assignee_id']),
      Arrow::StringArray.new(@columns['assignee_name']),
      Arrow::StringArray.new(@columns['assignee_email']),
      Arrow::Int64Array.new(@columns['team_id']),
      Arrow::StringArray.new(@columns['team_name']),
      Arrow::Int64Array.new(@columns['account_id']),
      Arrow::StringArray.new(@columns['additional_attributes']),
      Arrow::Int64Array.new(@columns['contact_last_seen_at']),
      Arrow::StringArray.new(@columns['custom_attributes']),
      Arrow::Int64Array.new(@columns['inbox_id']),
      Arrow::StringArray.new(@columns['inbox_name']),
      Arrow::StringArray.new(@columns['labels']),
      Arrow::BooleanArray.new(@columns['muted']),
      Arrow::Int64Array.new(@columns['snoozed_until']),
      Arrow::StringArray.new(@columns['status']),
      Arrow::BooleanArray.new(@columns['closed']),
      Arrow::Int64Array.new(@columns['created_at']),
      Arrow::Int64Array.new(@columns['timestamp']),
      Arrow::Int64Array.new(@columns['first_reply_created_at']),
      Arrow::Int64Array.new(@columns['unread_count']),
      Arrow::StringArray.new(@columns['last_non_activity_message']),
      Arrow::Int64Array.new(@columns['last_activity_at']),
      Arrow::StringArray.new(@columns['priority']),
      Arrow::StringArray.new(@columns['contact_kind'])
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
end