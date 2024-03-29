class Webhooks::StringeeController < ActionController::API
  def agents
    Rails.logger.info('Stringee webhook received get_list_agents request')

    request_body = JSON.parse(request.body.read)

    queue_id = request_body['queueId']
    inbox = Channel::StringeePhoneCall.find_by(queue_id: queue_id)&.inbox
    return unless inbox

    users = ::AutoAssignment::StringeeAssignmentService.new(inbox: inbox).perform

    response_data = generate_response_data(request_body, users)
    render json: response_data.to_json
  end

  private

  def generate_response_data(request_body, users)
    response_data = {
      version: 2,
      calls: []
    }

    call = request_body['calls'].first  # one queue is for only one number, so there should be one call at a time
    call_id = call['callId']

    agents = agent_list_for_call(users)

    response_data[:calls] << {
      callId: call_id,
      agents: agents
    }

    response_data
  end

  def agent_list_for_call(users)
    agents = []
    users.each do |user|
      agents <<
        {
          stringee_user_id: user.custom_attributes['agent_id'],
          routing_type: 1,
          answer_timeout: 15
        }
    end

    agents
  end
end
