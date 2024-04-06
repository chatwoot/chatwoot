class Webhooks::StringeeController < ActionController::API
  include SwitchLocale

  around_action :switch_locale

  def process_payload
    Rails.logger.info('Stringee webhook received events')
    Webhooks::StringeeEventsJob.perform_later(params.to_unsafe_hash)
    head :ok
  end

  def agents
    Rails.logger.info('Stringee webhook received get_list_agents request')

    request_body = JSON.parse(request.body.read)

    queue_id = request_body['queueId']
    inbox = Channel::StringeePhoneCall.find_by(queue_id: queue_id)&.inbox
    return unless inbox

    call = request_body['calls'].first  # one queue is for only one number, so there should be one call at a time
    from_number = call['from']
    last_conversation = find_last_conversation(inbox, from_number)

    users = ::AutoAssignment::StringeeAssignmentService.new(inbox: inbox, last_conversation: last_conversation).perform

    call_id = call['callId']
    response_data = generate_response_data(call_id, users)

    render json: response_data.to_json
  end

  private

  def find_last_conversation(inbox, from_number)
    from_number.prepend('+') unless from_number.start_with?('+')
    contact = Contact.find_by(phone_number: from_number)
    return unless contact

    inbox.conversations.where(contact_id: contact.id).order(updated_at: :desc).first
  end

  def generate_response_data(call_id, users)
    agents = agent_list_for_call(users)

    response_data = {
      version: 2,
      calls: []
    }
    response_data[:calls] << {
      callId: call_id,
      agents: agents
    }

    response_data
  end

  def agent_list_for_call(users)
    agents = []
    return agents if users.blank?

    users.each do |user|
      agents <<
        {
          stringee_user_id: user.stringee_user_id,
          routing_type: 1,
          answer_timeout: 15
        }
    end

    agents
  end
end
