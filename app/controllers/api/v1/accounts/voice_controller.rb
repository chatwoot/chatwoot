class Api::V1::Accounts::VoiceController < Api::V1::Accounts::BaseController
  before_action :fetch_conversation, only: [:end_call, :join_call, :reject_call, :call_status]
  
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
  
  def join_call
    call_sid = params[:call_sid] || @conversation.additional_attributes&.dig('call_sid')
    return render json: { error: 'No active call found' }, status: :not_found unless call_sid
    
    # Get the inbox and channel information
    inbox = @conversation.inbox
    channel = inbox&.channel
    
    if channel.is_a?(Channel::Voice) && channel.provider == 'twilio'
      config = channel.provider_config_hash
      
      begin
        # Create a Twilio client
        client = Twilio::REST::Client.new(config['account_sid'], config['auth_token'])
        
        # Get the conference SID from the conversation attributes
        # For incoming calls, Twilio typically places the caller in a conference that agents can join
        conference_sid = @conversation.additional_attributes&.dig('conference_sid')
        
        if conference_sid
          # Create a call that connects the agent to the conference
          client.calls.create(
            to: current_user.phone_number || config['agent_phone_number'],
            from: channel.phone_number,
            status_callback: "#{ENV.fetch('FRONTEND_URL', nil)}/twilio/voice/status_callback",
            status_callback_event: ['initiated', 'ringing', 'answered', 'completed'],
            status_callback_method: 'POST',
            url: "#{ENV.fetch('FRONTEND_URL', nil)}/twilio/voice/twiml?conference_sid=#{conference_sid}&agent_id=#{current_user.id}"
          )
          
          # Update conversation to show agent joined
          @conversation.additional_attributes ||= {}
          @conversation.additional_attributes['agent_joined'] = true
          @conversation.additional_attributes['joined_at'] = Time.now.to_i
          @conversation.additional_attributes['joined_by'] = {
            id: current_user.id,
            name: current_user.name
          }
          @conversation.save!
          
          # Create an activity message noting the agent joined
          Messages::MessageBuilder.new(
            nil, 
            @conversation, 
            { 
              content: "#{current_user.name} joined the call", 
              message_type: :activity,
              additional_attributes: { 
                call_sid: call_sid,
                conference_sid: conference_sid,
                joined_by: current_user.name,
                joined_at: Time.now.to_i
              }
            }
          ).perform
          
          render json: { 
            status: 'success', 
            message: 'Agent joining call',
            conference_sid: conference_sid
          }
        else
          render json: { error: 'Conference not found for this call' }, status: :unprocessable_entity
        end
      rescue Twilio::REST::RestError => e
        render json: { error: "Failed to join call: #{e.message}" }, status: :internal_server_error
      end
    else
      render json: { error: 'Unsupported channel provider for call control' }, status: :unprocessable_entity
    end
  end
  
  def reject_call
    call_sid = params[:call_sid] || @conversation.additional_attributes&.dig('call_sid')
    return render json: { error: 'No active call found' }, status: :not_found unless call_sid
    
    # Get the inbox and channel information
    inbox = @conversation.inbox
    channel = inbox&.channel
    
    if channel.is_a?(Channel::Voice) && channel.provider == 'twilio'
      # Update conversation to show agent rejected call
      @conversation.additional_attributes ||= {}
      @conversation.additional_attributes['agent_rejected'] = true
      @conversation.additional_attributes['rejected_at'] = Time.now.to_i
      @conversation.additional_attributes['rejected_by'] = {
        id: current_user.id,
        name: current_user.name
      }
      @conversation.save!
      
      # Create an activity message noting the agent rejected the call
      Messages::MessageBuilder.new(
        nil, 
        @conversation, 
        { 
          content: "#{current_user.name} declined to answer", 
          message_type: :activity,
          additional_attributes: { 
            call_sid: call_sid,
            rejected_by: current_user.name,
            rejected_at: Time.now.to_i
          }
        }
      ).perform
      
      render json: { 
        status: 'success', 
        message: 'Call rejected by agent'
      }
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