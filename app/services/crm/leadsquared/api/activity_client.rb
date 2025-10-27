class Crm::Leadsquared::Api::ActivityClient < Crm::Leadsquared::Api::BaseClient
  # https://apidocs.leadsquared.com/post-an-activity-to-lead/#api
  def post_activity(prospect_id, activity_event, activity_note)
    raise ArgumentError, 'Prospect ID is required' if prospect_id.blank?
    raise ArgumentError, 'Activity event code is required' if activity_event.blank?

    path = 'ProspectActivity.svc/Create'

    body = {
      'RelatedProspectId' => prospect_id,
      'ActivityEvent' => activity_event,
      'ActivityNote' => activity_note
    }

    response = post(path, {}, body)
    response['Message']['Id']
  end

  def create_activity_type(name:, score:, direction: 0)
    raise ArgumentError, 'Activity name is required' if name.blank?

    path = 'ProspectActivity.svc/CreateType'
    body = {
      'ActivityEventName' => name,
      'Score' => score.to_i,
      'Direction' => direction.to_i,
      'AllowAttachments' => 1
    }

    response = post(path, {}, body)
    response['Message']['Id']
  end

  def fetch_activity_types
    get('ProspectActivity.svc/ActivityTypes.Get')
  end

  # https://apidocs.leadsquared.com/file-upload-to-leads/
  def upload_file(activity_event_code, file_name, file_content)
    raise ArgumentError, 'Activity event code is required' if activity_event_code.blank?
    raise ArgumentError, 'File name is required' if file_name.blank?
    raise ArgumentError, 'File content is required' if file_content.blank?

    # Derive the files host from the endpoint URL
    files_host = derive_files_host

    form_data = {
      FileType: 0,           # 0 = Document
      Entity: 1,             # 1 = Activity
      Id: activity_event_code.to_s,
      FileStorageType: 0,    # 0 = Permanent
      EnableResize: false,
      AccessKey: @access_key,
      SecretKey: @secret_key
    }

    multipart_post("#{files_host}/File/Upload", file_name, file_content, form_data)
  end

  # https://apidocs.leadsquared.com/attach-a-file-to-activities/#api
  def attach_file_to_activity(activity_id, file_url, file_name, description = nil)
    raise ArgumentError, 'Activity ID is required' if activity_id.blank?
    raise ArgumentError, 'File URL is required' if file_url.blank?
    raise ArgumentError, 'File name is required' if file_name.blank?

    path = 'ProspectActivity.svc/Attachment/Add'
    body = {
      'ProspectActivityId' => activity_id,
      'AttachmentName' => file_name,
      'Description' => description || 'Full conversation transcript',
      'AttachmentFile' => file_url
    }

    response = post(path, {}, body)
    response['Message']['Id']
  end

  private

  def derive_files_host
    # Convert API host to files host
    # api-in21.leadsquared.com -> files-in21.leadsquared.com
    # api-us11.leadsquared.com -> files-us11.leadsquared.com
    # api.leadsquared.com -> files.leadsquared.com
    host = URI.parse(@base_uri).host
    files_host = host.gsub(/^api(-)?/, 'files\1')
    "https://#{files_host}"
  end
end
