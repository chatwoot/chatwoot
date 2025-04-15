class Crm::Leadsquared::Api::ActivityClient < Crm::Leadsquared::Api::BaseClient
  # https://apidocs.leadsquared.com/post-an-activity-to-lead/#api
  def post_activity(prospect_id, activity_event, activity_note)
    return { success: false, error: 'Prospect ID is required' } if prospect_id.blank?
    return { success: false, error: 'Activity event code is required' } if activity_event.blank?

    path = 'ProspectActivity.svc/Create'

    body = {
      'RelatedProspectId' => prospect_id,
      'ActivityEvent' => activity_event,
      'ActivityNote' => activity_note
    }

    response = post(path, {}, body)
    handle_activity_response(response)
  end

  def create_activity_type(name:, score:, direction: 0)
    path = 'ProspectActivity.svc/CreateType'
    body = {
      'ActivityEventName' => name,
      'Score' => score.to_i,
      'Direction' => direction.to_i
    }

    response = post(path, {}, body)
    handle_activity_response(response)
  end

  private

  def handle_activity_response(response)
    if response_ok?(response)
      { success: true, activity_id: response[:data]['Message']['Id'] }
    else
      Rails.logger.error("Call to LeadSquared activity API failed with [#{response[:code]}] #{response[:error]}")
      { success: false, error: 'Activity not created' }
    end
  end

  def response_ok?(response)
    response[:success] &&
      response[:data]['Status'] == 'Success' &&
      response[:data]['Message'] &&
      response[:data]['Message']['Id']
  end
end
