class Crm::Leadsquared::Api::ActivityClient < Crm::Leadsquared::Api::BaseClient
  # https://apidocs.leadsquared.com/post-an-activity-to-lead/#api
  def post_activity(prospect_id, activity_event, activity_note, activity_date_time = nil)
    return { success: false, error: 'Prospect ID is required' } if prospect_id.blank?
    return { success: false, error: 'Activity event code is required' } if activity_event.blank?

    path = '/v2/ProspectActivity.svc/Create'

    body = {
      'RelatedProspectId' => prospect_id,
      'ActivityEvent' => activity_event,
      'ActivityNote' => activity_note
    }

    # Add activity date time if provided
    body['ActivityDateTime'] = activity_date_time if activity_date_time.present?

    response = post(path, {}, body)
    handle_activity_response(response)
  end

  private

  def handle_activity_response(response)
    if valid_activity_response?(response)
      { success: true, data: response[:data]['Value'] }
    elsif response[:success]
      # Response was technically successful but no activity ID returned
      { success: false, error: 'Activity not created' }
    else
      response
    end
  end

  def valid_activity_response?(response)
    response[:success] &&
      valid_response_data?(response[:data])
  end

  def valid_response_data?(data)
    data.is_a?(Hash) &&
      data['Status'] == 'Success' &&
      data['Value'].present? &&
      data['Value']['Id'].present?
  end
end
