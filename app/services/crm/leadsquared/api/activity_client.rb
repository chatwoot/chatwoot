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
      'Direction' => direction.to_i
    }

    response = post(path, {}, body)
    response['Message']['Id']
  end

  def fetch_activity_types
    get('ProspectActivity.svc/ActivityTypes.Get')
  end
end
