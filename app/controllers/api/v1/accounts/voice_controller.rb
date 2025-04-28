class Api::V1::Accounts::VoiceController < Api::V1::Accounts::BaseController
  before_action :fetch_conversation, only: [:end_call, :call_status]
  
  def end_call
    call_sid = params[:call_sid] || @conversation.additional_attributes&.dig('call_sid')
    return render json: { error: 'No active call found' }, status: :not_found unless call_sid
    
    # Get the inbox and channel information
    inbox = @conversation.inbox
    channel = inbox&.channel
    
    if channel.is_a?(Channel::Voice) && channel.provider == 'twilio'
      config = channel.provider_config_hash
      
      begin
        # Create a Twilio client and end the call
        client = Twilio::REST::Client.new(config['account_sid'], config['auth_token'])
        call = client.calls(call_sid).fetch
        
        # Only try to end the call if it's still in progress
        if call.status == 'in-progress' || call.status == 'ringing'
          client.calls(call_sid).update(status: 'completed')
          
          # Update conversation call status
          @conversation.additional_attributes ||= {}
          @conversation.additional_attributes['call_status'] = 'completed'
          @conversation.save!
          
          # Create an activity message noting the call has ended
          Messages::MessageBuilder.new(
            nil, 
            @conversation, 
            { 
              content: 'Call ended by agent', 
              message_type: :activity,
              additional_attributes: { 
                call_sid: call_sid,
                call_status: 'completed',
                ended_by: current_user.name
              }
            }
          ).perform
          
          render json: { status: 'success', message: 'Call successfully ended' }
        else
          render json: { status: 'success', message: "Call already in '#{call.status}' state" } 
        end
      rescue Twilio::REST::RestError => e
        render json: { error: "Failed to end call: #{e.message}" }, status: :internal_server_error
      end
    else
      render json: { error: 'Unsupported channel provider for call control' }, status: :unprocessable_entity
    end
  end
  
  def call_status
    call_sid = @conversation.additional_attributes&.dig('call_sid')
    return render json: { error: 'No call found' }, status: :not_found unless call_sid
    
    # Get the inbox and channel information
    inbox = @conversation.inbox
    channel = inbox&.channel
    
    if channel.is_a?(Channel::Voice) && channel.provider == 'twilio'
      config = channel.provider_config_hash
      
      begin
        # Create a Twilio client and fetch the call status
        client = Twilio::REST::Client.new(config['account_sid'], config['auth_token'])
        call = client.calls(call_sid).fetch
        
        render json: { 
          status: call.status,
          duration: call.duration,
          direction: call.direction,
          from: call.from,
          to: call.to,
          start_time: call.start_time,
          end_time: call.end_time
        }
      rescue Twilio::REST::RestError => e
        render json: { error: "Failed to fetch call status: #{e.message}" }, status: :internal_server_error
      end
    else
      render json: { error: 'Unsupported channel provider for call status' }, status: :unprocessable_entity
    end
  end
  
  private
  
  def fetch_conversation
    @conversation = Current.account.conversations.find(params[:id] || params[:conversation_id])
  end
end